import csv
import os
# from multiprocessing import Process
from subprocess import Popen

service_port="6000"
times="2"

services={
    "11":["cwa-verification", "market", "project-tracking-system"],
    "evo8":["ncs", "news", "scs", "features-service", "languagetool", "proxyprint", "restcountries", "scout-api","ocvn"],
     "8":["genome-nexus",
          "person-controller", "rest-study", "user-management", "problem-controller", "spring-batch-rest","erc20-rest-service"], #"spring-boot-sample-app"
 
}
used_vm_porst=[]
service_times={}
commands = []
done={}

def run_service_tool(ports_csv):
    available_vm_ports={}
    with open(ports_csv, mode ='r')as file:
        csvFile = csv.reader(file)
        for lines in csvFile:
            vm_port = lines[0]
            if vm_port not in available_vm_ports:
                available_vm_ports[vm_port] = lines

    for version in services:
        for service in services[version]:
            if service not in done:
                done[service] = []
            if service not in service_times:
                service_times[service] = 0
            while service_times[service]<5:
                for vm_port in available_vm_ports:
                    if vm_port not in used_vm_porst:
                        used_vm_porst.append(vm_port)
                        vm_host = available_vm_ports[vm_port][1]
                        lab_name = available_vm_ports[vm_port][2]
                        vm_name = available_vm_ports[vm_port][3]
                        resource_group = available_vm_ports[vm_port][4]
                        if service == "erc20-rest-service":
                            cmd_list = ["echo", service, "RestGPT", version, ", you can run it on", vm_port,vm_host,lab_name,vm_name,resource_group," |tee",lab_name+"_"+vm_port +"_"+vm_name+"_"+restgpt+"_"+service+"_res.log"]
                        # elif service == "genome-nexus":
                            # cmd_list = ["echo", service, tool, version, ", you can run it on", vm_port,vm_host,lab_name,vm_name,resource_group," |tee",lab_name+"_"+vm_port +"_"+vm_name+"_"+tool+"_"+service+"_res.log"]
                        else:
                            cmd_list = ["bash", "-x", "gpt_connect_vm.sh",vm_port,vm_host,service,version,service_port,times,lab_name,vm_name,resource_group," |tee",lab_name+"_"+vm_port +"_"+vm_name+"_"+"restgpt"+"_"+service+"_res.log"]
                        cmds = " ".join(cmd_list)
                        commands.append(cmds)
                        print(cmds)
                        break
                service_times[service] += 1
                               

if __name__ == "__main__":
    run_service_tool("p2.csv")
    procs = [ Popen(i,shell=True) for i in commands ]
    for p in procs:
        p.wait()



