import os
from azure.identity import AzureCliCredential
from azure.mgmt.compute import ComputeManagementClient

try:
    # Authentication using Azure CLI context
    credential = AzureCliCredential()
    
    # Automatically retrieve the current subscription ID
    subscription_id = os.popen("az account show --query id -o tsv").read().strip()
    
    if not subscription_id:
        print("Error: Not logged into Azure. Please run 'az login' first.")
    else:
        # Initialize the Compute Management Client
        compute_client = ComputeManagementClient(credential, subscription_id)
        RESOURCE_GROUP = "rg-automation-project"

        print(f"Scanning Resource Group: {RESOURCE_GROUP} for optimization opportunities...")

        # List all Virtual Machines in the resource group
        vms = compute_client.virtual_machines.list(RESOURCE_GROUP)
        
        found_target = False
        for vm in vms:
            # Filter VMs based on the 'AutoShutdown' Tag defined in Terraform
            if vm.tags and vm.tags.get("AutoShutdown") == "True":
                found_target = True
                print(f"Target found: {vm.name}. Current policy: AutoShutdown=True")
                print(f"Initiating deallocation for {vm.name} to save costs...")
                
                # Start the deallocation process
                poller = compute_client.virtual_machines.begin_deallocate(RESOURCE_GROUP, vm.name)
                poller.wait()
                print(f"SUCCESS: {vm.name} has been deallocated and is no longer incurring costs.")

        if not found_target:
            print("No virtual machines found with the 'AutoShutdown=True' tag.")

except Exception as e:
    print(f"An error occurred: {str(e)}")