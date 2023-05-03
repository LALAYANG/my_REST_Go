import sys
import time
import subprocess
import os


def blackbox(swagger, port, service,log_dir,api_key):
    curdir = os.getcwd()
    if not os.path.exists(log_dir):
        os.mkdir(log_dir)
    if not os.path.exists(curdir + "/UIUC-API-Tester/output"):
        os.mkdir(curdir + "/UIUC-API-Tester/output")
    subprocess.run("cd UIUC-API-Tester/open-api-processor/target && java -jar open-api-processor-1.0-SNAPSHOT-jar-with-dependencies.jar " + swagger + " " + curdir + "/UIUC-API-Tester/output", shell=True)
    subprocess.run('cd UIUC-API-Tester/APITester && python3 integrate_enum.py '+str(service)+'', shell=True)
    print("uiuc tool started")
    subprocess.run('cd UIUC-API-Tester/APITester && python3 uiuc_api_tester.py '+str(service)+" "+str(api_key) +' >'+log_dir+ '/uiuc_test_'+str(port)+"_"+service+'.txt', shell=True)
    #subprocess.run('cd UIUC-API-Tester/APITester && python3 uiuc_api_tester.py '+str(service)+'', shell=True)
    print("uiuc tool ended")


if __name__ == "__main__":
    # this is only for blackbox. Please do not use this for whitebox testing
    port = sys.argv[1]
    service = sys.argv[2]
    log_dir=sys.argv[3]
    api_key=sys.argv[4]

    curdir = os.getcwd()
    # services = ["market","user-management", "cwa-verification","ncs", "proxyprint", "restcountries", "scout-api", "erc20-rest-service", "person-controller", "rest-study", "spring-batch-rest", "project-tracking-system"]
    

    # for service in services:
        # start the service
    subprocess.run("python3 run_service.py " + service + " " + str(port) + " blackbox "+log_dir, shell=True)
    print("service: "+ service + " has been started. You can check the same with tmux ls command in a new terminal")

    # initate jacoco agent
    cov_session = service + "_cov"
    subprocess.run("tmux new -d -s " + cov_session + " sh get_cov.sh " + str(port), shell=True)
    print("jacoc agent initated")

    if service == "features-service":
        blackbox(os.path.join(curdir, "doc/features_swagger.json"), port, service,log_dir)
    elif service == "news":
        blackbox(os.path.join(curdir, "doc/news_swagger.json"), port, service,log_dir)
    elif service == 'scs':
        blackbox(os.path.join(curdir, "doc/scs_swagger.json"), port, service,log_dir)
    elif service == 'ocvn':
        blackbox(os.path.join(curdir, "doc/ocvn_swagger.json"), port, service,log_dir)
    elif service == 'languagetool':
        blackbox(os.path.join(curdir, "doc/languagetool_swagger.json"), port, service,log_dir)
    elif service == 'genome-nexus':
        blackbox(os.path.join(curdir, "doc/genome_swagger.json"), port, service,log_dir)
    elif service == 'problem-controller':
        blackbox(os.path.join(curdir, "doc/problem_swagger.json"), port, service,log_dir)
    elif service == "ncs":
        blackbox(os.path.join(curdir, "doc/ncs_swagger.json"), port, service,log_dir)
    elif service == "proxyprint":
        blackbox(os.path.join(curdir, "doc/proxyprint_swagger.json"), port, service,log_dir)
    elif service == "restcountries":
        blackbox(os.path.join(curdir, "doc/restcountries_openapi.yaml"), port, service,log_dir)
    elif service == "scout-api":
        blackbox(os.path.join(curdir, "doc/scout_swagger.json"), port, service,log_dir)
    elif service == "erc20-rest-service":
        blackbox(os.path.join(curdir, "doc/erc20_swagger.json"), port, service,log_dir)
    elif service == "person-controller":
        blackbox(os.path.join(curdir, "doc/person_swagger.json"), port, service,log_dir)
    elif service == "rest-study":
        blackbox(os.path.join(curdir, "doc/rest_swagger.json"), port, service,log_dir)
    elif service == "spring-batch-rest":
        blackbox(os.path.join(curdir, "doc/springbatch_openapi.yaml"), port, service,log_dir)
    elif service == "user-management":
        blackbox(os.path.join(curdir, "doc/user_swagger.json"), port, service,log_dir)
    elif service == "cwa-verification":
        blackbox(os.path.join(curdir, "doc/cwa_openapi.yaml"), port, service,log_dir)
    elif service == "market":
        blackbox(os.path.join(curdir, "doc/market_swagger.json"), port, service,log_dir)
    elif service == "project-tracking-system":
        blackbox(os.path.join(curdir, "doc/project_swagger.json"), port, service,log_dir)
    else:
        print("select proper service")

        # port = port + 10
    

    print("Experiments done. We are safely closing the service now.")

    time.sleep(180)
    subprocess.run("tmux kill-sess -t " + service, shell=True)


