import json
import subprocess

def lambda_handler(event, context):
    # Executa o comando Terraform destroy
    process = subprocess.Popen(['terraform', 'destroy', '-auto-approve'], cwd='/path/to/your/terraform/config', stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, stderr = process.communicate()

    return {
        'statusCode': 200,
        'body': json.dumps('Terraform destroy executed')
    }
