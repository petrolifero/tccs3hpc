import json
import uuid

objectSizes=[10,100,1000] #[10,100,1000,10000,100000,1000000,10000000,100000000]
fsxPerformances=[1] #[1,10,100,1000,10000,100000,1000000]:
modes=["fsx","s3"] #["fsx","s3","fsxOptimal"]
cluster_sizes=[3,5,10,15] #[3,5,10,15,20]
configs=[]


for object_size in objectSizes:
    for mode in modes:
        for fsxPerformance in fsxPerformances:
            for instanceType in ["t2.micro"]:
                for cluster_size in cluster_sizes:
                    d=dict()
                    d["id"]=str(uuid.uuid4())
                    d["object_size"]=object_size
                    d["mode"]=mode
                    if mode == "fsx" or mode == "fsxOptimal":
                        d["fsxPerformance1"]=fsxPerformance
                    d["instance_type"]=instanceType
                    d["cluster_size"]=cluster_size
                    configs.append(d)


if __name__ == "__main__":
    print(json.dumps(configs,indent=4))
