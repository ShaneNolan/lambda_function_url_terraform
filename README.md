# Creating an HTTPS Lambda Endpoint without API Gateway

## Using Functional URLs and Terraform for Automated Deployment

<center>

![](https://cdn-images-1.medium.com/max/2000/1*2ITtm6wPmCIykfN-CHun_g.png)

</center>

Amazon Web Services (AWS) recently announced [Function URLs](https://aws.amazon.com/about-aws/whats-new/2022/04/aws-lambda-function-urls-built-in-https-endpoints/), a new in-built feature that allows you to invoke your functions through an HTTPS endpoint. By default, the endpoint is secure using [AWS Identity Access Management](https://aws.amazon.com/iam/) (IAM) but you can allow public access with optional Cross-Origin Resource Sharing (CORS) configurations and/or custom authorisation logic. Originally, if you wanted to invoke a Lambda function publicly via HTTPS you would need to set up and configure [AWS API Gateway](https://aws.amazon.com/api-gateway/) or [AWS Elastic Load Balancing](https://aws.amazon.com/elasticloadbalancing/) and pay additional fees once you exceeded their free tier. Fortunately, Function URLs don't incur an additional cost 🎉. I’d recommend you continue to use these services if you’re building a serverless REST API or require additional features such as request-response [transformations](https://docs.aws.amazon.com/apigateway/latest/developerguide/rest-api-data-transformations.html). For small use-cases such as webhooks or determining the price of a cryptocurrency, Function URLs are more suited.

This blog post will demonstrate how to create an HTTPS Lambda endpoint using Function URLs, [Python](https://python.org/) and [Terraform](https://www.terraform.io/), an open-source infrastructure as code tool. If you’d rather not use Terraform, Function URLs can be created directly via the AWS user interface (UI). You can follow the official AWS guide [here](https://aws.amazon.com/blogs/aws/announcing-aws-lambda-function-urls-built-in-https-endpoints-for-single-function-microservices/). You can use any compatible programming language with AWS Lambda for this demonstration since the principles are the same. You can view the project's source code on [Github](https://github.com/ShaneNolan/lambda_function_url_terraform).

## Python Lambda Function

First, create a Python project with main.py being the entry point for Lambda. I recommend using [this modern Python development environment](https://medium.com/@shanenullain/creating-a-modern-python-development-environment-3d383c944877) for a more straightforward implementation but your own will suffice. This project will use the Python version 3.9.0 . You can view a list of supported versions [here](https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html). Your project directory structure should replicate this:

    .
    ├── .editorconfig
    ├── CHANGELOG.md
    ├── README.md
    ├── lambda_function_url_terraform
    │   ├── __init__.py
    │   └── main.py
    ├── poetry.lock
    ├── pyproject.toml
    ├── setup.cfg
    └── tests
        ├── __init__.py
        └── test_main.py

    2 directories, 10 files

For this example, the main.py Lambda handler will return a JSON object with a body containing a message and status code of 200.

![Python main.py Lambda Handler](https://cdn-images-1.medium.com/max/2948/1*DjbjR52dDmAku0NTuRt9NA.png)

To ensure the Lambda handler is working as expected write a unit test in tests/test_main.py to validate its response.

![Unit test to validate the Lambda handler's response.](https://cdn-images-1.medium.com/max/2608/1*ao3oJTFk5gyHCUB-xnV-fw.png)

## Terraform Deployment

If you don’t have Terraform already installed, you can follow the [official installation documentation.](http://HashiCorp distributes Terraform as a binary package. You can also install Terraform using popular package managers.) Once installed, confirm the installation was successful by executing:

![Confirmation of Terraforms installation.](https://cdn-images-1.medium.com/max/2000/1*lL0YsyFAvtSDuAnrkzPj8Q.png)

First, create the required Terraform deployment file main.tf at the top level of your Python project. Declare 1.0.0 as the Terraform version and 4.9.0 as the Hashicorp AWS provider version since that's when Function URLs functionality was implemented. You can review the merge request [here](https://github.com/hashicorp/terraform-provider-aws/pull/24053). Next, declare the AWS region, for example eu-west-1 . Once declared main.tf should look like this:

![Initial Terraform deployment code.](https://cdn-images-1.medium.com/max/2000/1*gSyNkAXEbqHR-YL57xesZA.png)

Before the Lambda function can be implemented, an IAM role with a [trust policy](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_terms-and-concepts.html) needs to be created. In this case, the AWS Lambda service will be trusted and allowed to call the AWS Security Token Service (STS) AssumeRole action. Append the IAM role resource to main.tf file. Its implementation should look like this:

![Lambda IAM role with required trust policy.](https://cdn-images-1.medium.com/max/2000/1*wAQoksZCoNr3-VEZnHaTKw.png)

Execute the following commands to create a zip file called package.zip containing the projects source code and its requirements for Lambda:

    # Install zip package to zip files/folders:
    sudo apt-get install zip

    poetry build; 
    poetry run pip install --upgrade -t package dist/*.whl;
    (cd package; zip -r ../package.zip . -x '*.pyc';)

    # Pip installation without Poetry or zip:
    pip freeze > requirements.txt
    pip install -r requirements.txt -t package
    # zip the package folder.

Once packaged the Lambda function is ready to be implemented. Depending on your setup you may need to modify the following attributes:

* runtime depending on your Python version.

* function_name the name you want to give your Lambda function.

* handler the path to your [Lambda handler](https://docs.aws.amazon.com/lambda/latest/dg/python-handler.html).

The Lambda function resource should look like this:

![Terraform AWS Lambda function resource code.](https://cdn-images-1.medium.com/max/2608/1*eNIPsJGBtjMR6SWe3TO80w.png)

The filename attribute is the filename along with the extension of our packaged project. Similarly, the source_code_hash attribute is used to determine if the packaged project has been updated, i.e. a code change. The role attribute is a reference to the previously implemented IAM role. Append the Lambda function to main.tf .

Lastly, create the Function URL resource and save the generated URL.The authorization_type is set to NONE , meaning it allows public access. You have the option of restricting access to authenticated IAM users only, as well as CORS configuration capabilities. You can read about them [here](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function_url). The Lambda Function URL resource should look like this:

![Terraform AWS Lambda Function URL resource code.](https://cdn-images-1.medium.com/max/2508/1*TKRTthXAbAvDtv3twMRMSw.png)

The output resource function_url saves the generated Function URL. Append both the Function URL and output resource to main.tf . With all the Terraform components together, main.tf should replicate this:
{% gist https://gist.github.com/ShaneNolan/4d0c32d3db2976b180470769928ce5e2.js %}
Deploying with Terraform requires only a single command after the infrastructure is coded but first, you need to initialise Terraform inside of the project by executing terraform init . Additionally, set your AWS_ACCESS_KEY_ID , AWS_SECRET_ACCESS_KEY and AWS_REGION via the command line. If you’re unfamiliar with configuring your AWS credentials you can read more about it on the official [AWS](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html) and [Terraform](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#environment-variables) documentation. 
Once initialised, deploy your Lambda function using terraform apply and accept the confirmation of the required changes. After deployment, it will output the Lambda Function URL 🎉.

![Terraform AWS Lambda Function URL deployment.](https://cdn-images-1.medium.com/max/3398/1*ydC_2cJbnRo65TM9Mver7Q.gif)

Test the public endpoint by either opening the URL in a browser or using an API testing tool such as [httpie](https://httpie.io/). The below example uses Terraform to retrieve the generated Function URL via terraform output and a GET request is submitted to the URL via httpie.

![httpie GET request to the Lambda Function URL.](https://cdn-images-1.medium.com/max/3398/1*GNhtY0Hsrst1BEGugU-ILA.gif)


