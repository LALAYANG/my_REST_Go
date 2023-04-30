echo STARTING at $(date)
git rev-parse HEAD

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

start_vm(){
    az lab vm Start --lab-name ${lab_name} --name ${vm_name} --resource-group ${lab_name}
}

stop_vm(){
    az lab vm Stop --lab-name ${lab_name} --name ${vm_name} --resource-group ${lab_name}
}

run_tool_service_pair(){
    sshpass -p "YANGc9" ssh -o StrictHostKeyChecking=no -p ${vm_port} -t yangc9@$vm_host '
        sudo apt-get update
        sudo apt-get install git
        sudo rm -rf my_REST_Go
        git clone https://github.com/LALAYANG/my_REST_Go
        cd my_REST_Go
        bash -x run_one.sh' ${service} ${service_version} ${tool} ${service_port} ${times}
        # 'echo' $service $service_version $tool $service_port $times
}

print_res(){
    mkdir -p res
    sshpass -p "YANGc9" ssh -o StrictHostKeyChecking=no -p ${vm_port} -t yangc9@$vm_host '
        echo ========================RESULT=============================
        ls /home/yangc9/my_REST_Go/REST_Go/logs/fuzzing_logs/*/*/res.csv
        cat /home/yangc9/my_REST_Go/REST_Go/logs/fuzzing_logs/*/*/res.csv
        echo ========================END=============================
        cd /home/yangc9/my_REST_Go/
        sudo apt install zip -y
        zip -r' ${lab_name}${service}${service_port}${tool}${vm_port}'.zip  /home/yangc9/my_REST_Go/REST_Go/logs'
}

download(){
    sshpass -p "YANGc9" scp -P ${vm_port} yangc9@${vm_host}:/home/yangc9/my_REST_Go/${lab_name}${service}${service_port}${tool}${vm_port}.zip res
}     


resize_vm_disk
# start_vm
run_tool_service_pair
print_res
download
stop_vm

echo STARTING at $(date)