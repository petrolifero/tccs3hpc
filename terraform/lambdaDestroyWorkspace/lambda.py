import os
import subprocess
import json
import boto3

def lambda_handler(event, context):
    # Parâmetros passados via evento
    workspace_name = event['workspace_name']
    git_repo = event['git_repo']

    # Diretório onde o terraform e as configurações serão clonados
    terraform_dir = os.getenv("LAMBDA_TASK_ROOT")
    terraform_binary = os.path.join(terraform_dir, 'terraform')
    
    # Clonando o repositório git
    if not os.path.exists(terraform_dir):
        os.makedirs(terraform_dir)
    
    git_clone_command = ['git', 'clone', git_repo, terraform_dir]
    subprocess.check_call(git_clone_command)

    # Comandos Terraform
    terraform_init_command = [terraform_binary, 'init']
    terraform_select_workspace_command = [terraform_binary, 'workspace', 'select', workspace_name]
    terraform_destroy_command = [terraform_binary, 'destroy', '-auto-approve']
    
    # Executando os comandos
    try:
        subprocess.check_call(terraform_init_command, cwd=terraform_dir)
        subprocess.check_call(terraform_select_workspace_command, cwd=terraform_dir)
        subprocess.check_call(terraform_destroy_command, cwd=terraform_dir)
    except subprocess.CalledProcessError as e:
        return {
            'statusCode': 500,
            'body': json.dumps(f'Erro ao executar terraform: {str(e)}')
        }

    return {
        'statusCode': 200,
        'body': json.dumps(f'Workspace {workspace_name} destruído com sucesso.')
    }
