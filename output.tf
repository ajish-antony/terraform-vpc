output "vpc" {
  value = aws_vpc.main.id
}

output "IGW" {
  value = aws_internet_gateway.igw.id
}

output "Route_Public" {
  value = aws_route_table.route-public.id
}

output "EIP" {
  value = aws_eip.eip.id
}

output "NAT" {
  value = aws_nat_gateway.nat.id
}

output "Route_Private" {
  value = aws_route_table.route-private.id
}
