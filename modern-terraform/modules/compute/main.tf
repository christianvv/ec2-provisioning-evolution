# Configure instance resources
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "devops_tools" {
  for_each = var.instances

  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = each.value.instance_type
  subnet_id              = var.private_subnet_ids[0]
  vpc_security_group_ids = [var.private_compute_sg_id]

  tags = {
    Name    = "${var.project_name}-${each.key}"
    Purpose = each.key
  }
}
