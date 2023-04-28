import csv
import os
# from multiprocessing import Process
from subprocess import Popen

service_port="7000"
times="3"

services={
    "8":["spring-boot-sample-app", "erc20-rest-service", "genome-nexus",
          "person-controller", "rest-study", "user-management", "problem-controller", "genome-nexus"],
    "11":["cwa-verification", "market", "project-tracking-system"],
    "evo8":["ncs", "news", "scs", "features-service", "languagetool", "proxyprint", "restcountries", "scout-api","ocvn"]
}
tools=["resttestgen", "restest", "restler", "evomaster-blackbox"]
used_vm_porst=[]
commands = []

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
            for tool in tools:
                for vm_port in available_vm_ports:
                    if vm_port not in used_vm_porst:
                        used_vm_porst.append(vm_port)
                        vm_host = available_vm_ports[vm_port][1]
                        lab_name = available_vm_ports[vm_port][2]
                        vm_name = available_vm_ports[vm_port][3]
                        resource_group = available_vm_ports[vm_port][4]
                        cmd_list = ["bash", "-x", "/Users/yangchen/Desktop/connect_vm.sh",vm_port,vm_host,service,version,tool,service_port,times,lab_name,vm_name,resource_group,"|tee",vm_host+".log"]
                        cmds = " ".join(cmd_list)
                        commands.append(cmds)
                        print(cmds)

if __name__ == "__main__":
    run_service_tool("/Users/yangchen/Desktop/ports.csv")
    procs = [ Popen(i,shell=True) for i in commands ]
    for p in procs:
        p.wait()


