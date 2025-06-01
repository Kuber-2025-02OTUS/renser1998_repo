import kopf
import yaml
import kubernetes
import time
from jinja2 import Environment, FileSystemLoader


def render_template(filename, vars_dict):
    """Returns JSON from rendered YAML manifest"""

    env = Environment(loader=FileSystemLoader('./templates'))
    template = env.get_template(filename)
    yaml_manifest = template.render(vars_dict)
    json_manifest = yaml.load(yaml_manifest, Loader=yaml.loader.SafeLoader)
    return json_manifest

@kopf.on.create('otus.homework', 'v1', 'mysqls')
def mysql_on_create(body, spec, logger, **kwargs):
    """Runs when MySQL objects are created."""

    # Saving the contents of the MySQL description from CR into variables
    name = body['metadata']['name']
    namespace = body['metadata']['namespace'] 
    image = spec['image']
    password = spec['password']
    database = spec['database']
    storage_size = spec['storage_size']


    # Generating JSON manifests for deploy
    persistent_volume = render_template(filename='my_mysql-pv.yml.j2', 
                                        vars_dict={
                                            'name': name, 
                                            'storage_size': storage_size
                                        })
    persistent_volume_claim = render_template(filename='my_mysql-pvc.yml.j2', 
                                              vars_dict={
                                                  'name': name, 
                                                  'storage_size': storage_size
                                              })
    service = render_template(filename='my_mysql-service.yml.j2', 
                              vars_dict={
                                  'name': name
                              })
    deployment = render_template(filename='my_mysql-deployment.yml.j2', 
                                 vars_dict={
                                     'name': name, 
                                     'image': image, 
                                     'password': password, 
                                     'database': database
                                 })
    
    # Determining that the created pvc, service and deployment are child resources to mysql custom resource
    # Thus, when deleting a CR, all pvc, service and deployment associated with it will be deleted
    kopf.append_owner_reference(persistent_volume_claim, owner=body)
    kopf.append_owner_reference(service, owner=body)
    kopf.append_owner_reference(deployment, owner=body)
    
    # Creating pv, pvc for mysql data and svc
    logger.info("Creating pv, pvc for mysql data and svc...")
    api = kubernetes.client.CoreV1Api()
    api.create_persistent_volume(persistent_volume)
    api.create_namespaced_persistent_volume_claim(namespace, persistent_volume_claim)
    api.create_namespaced_service(namespace, service)
    
    # Creating mysql deployment
    logger.info("Creating mysql deployment...")
    api = kubernetes.client.AppsV1Api()
    api.create_namespaced_deployment(namespace, deployment)
    try_count = 0

    while True:
        try:
            response = api.read_namespaced_deployment_status(name, namespace)
            if response.status.available_replicas != 1:
                logger.info("Waiting for mysql deployment to become ready...")
            else:
                if try_count > 20:
                    logger.error("mysql deployment is in unavailable state too long...")
                break
        except kubernetes.client.exceptions.ApiException as e:
            raise e
        
        time.sleep(10)
        try_count += 1
    
    message = f"MySQL instance {name} and its children resources created!"
    logger.info(message)
    return {'message': message}

@kopf.on.delete('otus.homework', 'v1', 'mysqls')
def delete_object_make_backup(body, spec, logger, **kwargs):
    """Creates backup and delete MySQL object with child resources"""

    name = body['metadata']['name']
    namespace = body['metadata']['namespace']
    image = spec['image']
    password = spec['password']
    database = spec['database']

    # Deleting pv
    api = kubernetes.client.CoreV1Api()
    api.delete_persistent_volume(f"{name}-pv")
    
    message = f"MySQL instance {name} and its children resources deleted!"
    logger.info(message)
    return {'message': message}
