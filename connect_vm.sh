vm_port=$1
vm_host=$2
service=$3
service_version=$4
tool=$5
service_port=$6
times=$7
lab_name=$8
vm_name=$9
resource_group=${10}

resize_vm_disk(){
    az lab vm Stop --lab-name ${lab_name} --name ${vm_name} --resource-group ${lab_name}
    az disk update --resource-group ${resource_group} --name ${vm_name} --size-gb 128
    az lab vm Start --lab-name ${lab_name} --name ${vm_name} --resource-group ${lab_name}
}

run_tool_service_pair(){

    sshpass -p "YANGc9" ssh -o StrictHostKeyChecking=no -p ${vm_port} -t yangc9@$vm_host '
        sudo apt-get update
        sudo apt-get install git
        git clone https://github.com/LALAYANG/my_REST_Go
        cd my_REST_Go
        bash -x run_one.sh' ${service} ${service_version} ${tool} ${service_port} ${times}
        # 'echo' $service $service_version $tool $service_port $times
}

resize_vm_disk
run_tool_service_pair