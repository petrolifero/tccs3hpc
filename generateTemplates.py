import json
from dataclasses import dataclass,asdict

@dataclass
class terraformConfiguration:
    type : str
    metadata : dict[str,str]


def s3Configurations():
    return [terraformConfiguration(type="S3",metadata=None)]

def lustreConfigurations():
    configs=[]
    for fileSize in ["10", "100", "1000", "10000", "100000", "1000000"]:
        configs.append(terraformConfiguration(type="LUSTRE", metadata={"fileSize":fileSize}))
    return configs

def configurations():
    return [asdict(c) for c in (s3Configurations() + lustreConfigurations())]

if __name__ == "__main__":
    print(json.dumps(configurations()))
