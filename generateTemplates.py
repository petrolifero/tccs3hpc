import json


configs=[]
for object_size in [10,100,1000,10000,100000,1000000,10000000,100000000]:
    for mode in ["fsx","s3","fsxOptimal"]:
        for fsxPerformance in [1,10,100,1000,10000,100000,1000000]:
            for instanceType in ["t2.nano"]:
                for cluster_size in [3,5,10,15,20]:
                    d=dict()
                    d["object_size"]=object_size
                    d["mode"]=mode
                    if mode == "fsx" or mode == "fsxOptimal":
                        d["fsxPerformance1"]=fsxPerformance
                    d["instance_type"]=instanceType
                    d["cluster_size"]=cluster_size
                    configs.append(d)


if __name__ == "__main__":
    print(json.dumps(configs,indent=4))
