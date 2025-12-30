# Copy this file to backend.hcl and replace placeholders with Story 1.1 outputs.
# Run `terraform -chdir=infra/bootstrap/remote-state output -raw <name>` to retrieve values.
region = "ap-southeast-1"
bucket = "tfstate-sandbox"
key    = "envs/dev/terraform.tfstate"
profile = "novamind-sandbox-kun"
tablestore_table    = "terraform_state_lock"
tablestore_endpoint = "https://tfstate-sandbox.ap-southeast-1.ots.aliyuncs.com"

# Example (do not commit real values):
# bucket = "tfstate-sandbox"
# tablestore_table = "terraform_state_lock"
# tablestore_endpoint = "https://tfstate-sandbox.ap-southeast-1.ots.aliyuncs.com"
