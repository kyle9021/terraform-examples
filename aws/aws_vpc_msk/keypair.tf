data "local_file" "msk-keypair-public" {
  filename = "${path.module}/keys/MSK-Keypair.pub"
}

resource "aws_key_pair" "MSK-Keypair-ec2-keypair" {
  key_name   = var.key_name
  public_key = data.local_file.msk-keypair-public.content
  tags = {
    yor_trace = "d4886f84-6f57-4881-9028-dd253cfdba62"
  }
}

output "msk-user-keypair" {
  value = aws_key_pair.MSK-Keypair-ec2-keypair.key_name
}