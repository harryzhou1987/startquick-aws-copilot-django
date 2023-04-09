# Use AWS Copilot to deploy a Django Website
Develop Branch is the default branch which includes the final version of the code for your reference. You need to update some variables with ***[]*** for the manifest yaml files for copilot deployment.

Follow the video to understand more about how AWS copilot works.

# Step By Step Guide
## Prerequisites
1. AWS CLI v2 and AWS Copilot are both installed.
2. AWS Credential is configured correctly.
## Prepare the initial code
1. Go to [django-start branch](https://github.com/harryzhou1987/startquick-aws-copilot-django/tree/django-start) and clone the branch to you local machine.
```
git clone -b django-start https://github.com/harryzhou1987/startquick-aws-copilot-django.git
```
2. Replace Django Secret Key in [settings.py](django-project/mysite/mysite/settings.py) file.
```python
SECRET_KEY = '[You Own Django Secret]'
```
3. Run Docker Compose to set up a local development environment
```
cd startquick-aws-copilot-django
docker compose up -d --build
```
4. Go to http://localhost:8080 in your web browser and check if the local environment is up.

## Set up and Deploy the containerized service on AWS Fargate using AWS Copilot
1. Initialize an App.
```
copilot app init
```
2. Create Environment named **test**.
```
copilot env init
```
Check the manifest.yaml for the environment and update it with VPC&subnet information as well as add certificate arn for the domain which you are going to use. You can also use your own existing VPC and subnets.
Then deploy the test environment using below command
```
copilot env deploy --name test
```
Once it is done, a new VPC is created. We need to create an RDS instance for this project. You can either create the database using AWS console or command line below
```
# Create a subnet group for RDS
aws rds create-db-subnet-group \
    --db-subnet-group-name [Subnet Group Name] \
    --db-subnet-group-description "DB subnet group for private subnets" \
    --subnet-ids [Private Subnet ID1] [Private Subnet ID2] ...

# Create security group for RDS
aws ec2 create-security-group \
    --group-name [Security Group Name] \
    --description "Security group for database instance in the private subnets" \
    --vpc-id [VPC ID]

# Here you can record the security group ID or check the security group ID via AWS console.

# Create ingress rule for the security group
aws ec2 authorize-security-group-ingress \
    --group-id [DB Security Group - Output of above command] \
    --protocol tcp \
    --port 3306 \
    --source-group [Service Security Group - Copilot created already]

# Create RDS instance
aws rds create-db-instance \
    --db-instance-identifier [DB Instance Name] \
    --db-instance-class db.t2.micro \
    --engine mysql \
    --engine-version 8.0 \
    --allocated-storage 20 \
    --master-username dbuser \
    --master-user-password SecretPassword \
    --db-subnet-group-name [Subnet Group Name] \
    --vpc-security-group-ids [DB Security Group] \
    --db-name djangodb \
    --no-multi-az
```
4. When the DB instance is ready, start the service in the test environment
```
copilot init
```
It should fail due to the missing alias for the load balancer. You need to add below in the environment part of the manifest yaml file.
```
environments:
  test:
    http:
      alias: # The "test" environment imported a certificate.
        - name: "[Domain Name for the Service]"
          hosted_zone: [Hosted Zone for your Domain]
```

5. Add variables for the service. Refer to docker compose yaml file.
DB Host needs to tbe the endpoint of your RDS instance.
```
      DB_HOST: [Endpoint - RDS instance]
      DB_NAME: djangodb
      DB_USER: dbuser
      DB_PASSWORD: SecretPassword
      ALLOWEDSOURCE: 0.0.0.0
      DEBUG: true
```
6. Add Allowed Host in your django project [settings.py](django-project/mysite/mysite/settings.py) file. I use below for the test environment.
```
ALLOWED_HOSTS = [
    ip_address,
    'localhost',
    'www.cloudcracker.click'  # Replace this with your own
]
```
7. Run below command to deploy the service again.
```
copilot svc deploy --env test
```
8. Go to Site URL in your web browser and check if the site is up.

## Create Deployment Pipeline
0. Check out to a new Git branch if needed.
```
git checkout -b "new-branch"
```
1. Run below to build the pipeline. The pipeline is using AWS Code Build and Code Pipeline.
```
copilot pipeline init
git add copilot/ && git commit -m "Adding pipeline artifacts" && git push
copilot pipeline deploy
```
2. During the deployment, you need to set up the authorization of your code repository for AWS.

## Final Test
Assuming your docker compose environment is still up.
1. Do the dev work locally and confirm your dev work via http://localhost:8080
2. Push the code to your remote repository and wait until the automatic deployment is done.

Easy as! You don't need to manually create the infrastructure for your containerized service and AWS did everything for you.
You can check CloudFormation to see what services AWS helps you create.

# Feedback
I might miss something. Please create a issue or [email me](harry.xiao.zhou@gmail.com) for any questions. Thank you.
