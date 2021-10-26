cat >> main.tf <<'EOF'
resource "aws_subnet" "web_subnet_1" {
  vpc_id            = "${aws_vpc.web_vpc.id}"
  cidr_block        = "192.168.100.0/25"
  availability_zone = "us-west-2a"

  tags {
    Name = "Web Subnet 1"
  }
}

resource "aws_subnet" "web_subnet_2" {
  vpc_id            = "${aws_vpc.web_vpc.id}"
  cidr_block        = "192.168.100.128/25"
  availability_zone = "us-west-2b"

  tags {
    Name = "Web Subnet 2"
  }
}

EOF
The subnets vpc_id argument use interpolation syntax to obtain the Web VPC ID. Attributes for a resource are listed on the Terraform docs page for the resource. For example, the attributes for AWS VPCs are listed here. To keep the configuration minimal, the subnets will be private subnets only accessible inside the VPC. That is, you won't add an internet gateway and modify route tables to make the instances accessible over the internet. The two subnet configurations have a lot of duplication. You will see how to avoid duplication in configurations in the next Step.

cat >> main.tf <<'EOF'
resource "aws_instance" "web" {
  ami           = "ami-0fb83677"
  instance_type = "t2.micro"
  subnet_id     = "${aws_subnet.web_subnet_1.id}"
  
  tags {
    Name = "Web Server 1"
  }
}

EOF
The subnet_id is set using interpolation syntax to the ID of the first web subnet. Terraform is able to determine the order it needs to create the resources to be able to use the interpolate the values. Particularly, web_subnet_1 must be created before web, and web_vpc must be created before both web_subnet_1 and web_subnet_2



cat >> main.tf <<'EOF'
resource "aws_subnet" "web_subnet" {
  # Use the count meta-parameter to create multiple copies
  count             = 2
  vpc_id            = "${aws_vpc.web_vpc.id}"
  # cidrsubnet function splits a cidr block into subnets
  cidr_block        = "${cidrsubnet(var.network_cidr, 1, count.index)}"
  # element retrieves a list element at a given index
  availability_zone = "${element(var.availability_zones, count.index)}"

  tags {
    Name = "Web Subnet ${count.index + 1}"
  }
}

resource "aws_instance" "web" {
  count         = "${var.instance_count}"
  # lookup returns a map value for a given key
  ami           = "${lookup(var.ami_ids, "us-west-2")}"
  instance_type = "t2.micro"
  # Use the subnet ids as an array and evenly distribute instances
  subnet_id     = "${element(aws_subnet.web_subnet.*.id, count.index % length(aws_subnet.web_subnet.*.id))}"
  
  tags {
    Name = "Web Server ${count.index + 1}"
  }
}

EOF
The count metaparameter allows you to create multiple copies of a resource. Interpolation using count.index allows you to modify the copies. index is zero for the first copy, one for the second, etc. For example, the instances are distributed between the two subnets that are created by using count.index to select between the subnets. There is no duplication between resources compared to the configuration 
