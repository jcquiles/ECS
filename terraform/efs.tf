resource "aws_efs_file_system" "foo" {
  tags = {
    Name = "ECS-EFS-FS"
  }
}

resource "aws_efs_mount_target" "mount" {
  file_system_id = aws_efs_file_system.foo.id
  subnet_id      = aws_subnet.alpha.id
}

// TODO: add security group for EFS Mount Target to allow access only from ECS Service security group