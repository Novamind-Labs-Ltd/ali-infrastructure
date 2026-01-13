# DNS Public Zone Module

Terraform module to create and manage AliCloud DNS public zones with optional DNS records.

## Features

- Creates AliCloud DNS public zones (`alicloud_alidns_domain`)
- Optional domain group for organizing multiple zones
- Flexible DNS record management (A, AAAA, CNAME, TXT, MX, NS, SRV)
- Outputs NS servers for delegation at your domain registrar
- Support for tagging and resource organization

## Prerequisites

- Domain must be already registered at a domain registrar
- Domain must not be added by another Alibaba Cloud account
- AliCloud credentials with DNS management permissions

## Usage

### Basic Usage (Zone Only)

```hcl
module "dns_zone" {
  source = "../../modules/dns-public-zone"

  domain_name = "example.com"

  tags = {
    environment = "dev"
    managed_by  = "terraform"
  }
}

# After apply, update NS records at your registrar
output "nameservers" {
  value = module.dns_zone.dns_servers
}
```

### With Domain Group

```hcl
module "dns_zone" {
  source = "../../modules/dns-public-zone"

  domain_name         = "example.com"
  create_domain_group = true
  domain_group_name   = "production-zones"
  remark              = "Production DNS zone for example.com"

  tags = {
    environment = "prod"
    managed_by  = "terraform"
  }
}
```

### With DNS Records

```hcl
module "dns_zone" {
  source = "../../modules/dns-public-zone"

  domain_name = "example.com"

  records = [
    # A record for apex domain
    {
      rr    = "@"
      type  = "A"
      value = "203.0.113.10"
      ttl   = 600
    },
    # CNAME for www
    {
      rr    = "www"
      type  = "CNAME"
      value = "example.com"
      ttl   = 600
    },
    # MX record for email
    {
      rr       = "@"
      type     = "MX"
      value    = "mail.example.com"
      ttl      = 3600
      priority = 10
    },
    # TXT record for SPF
    {
      rr    = "@"
      type  = "TXT"
      value = "v=spf1 include:_spf.google.com ~all"
      ttl   = 3600
    },
    # Wildcard A record
    {
      rr    = "*"
      type  = "A"
      value = "203.0.113.10"
      ttl   = 600
    }
  ]

  tags = {
    environment = "dev"
    managed_by  = "terraform"
  }
}
```

### Round-Robin DNS (Multiple A Records)

```hcl
module "dns_zone" {
  source = "../../modules/dns-public-zone"

  domain_name = "example.com"

  records = [
    # Round-robin A records for load balancing
    # Use explicit 'key' to avoid conflicts
    {
      key   = "A-www-server1"
      rr    = "www"
      type  = "A"
      value = "203.0.113.10"
      ttl   = 60
    },
    {
      key   = "A-www-server2"
      rr    = "www"
      type  = "A"
      value = "203.0.113.11"
      ttl   = 60
    },
    {
      key   = "A-www-server3"
      rr    = "www"
      type  = "A"
      value = "203.0.113.12"
      ttl   = 60
    }
  ]

  tags = {
    environment = "prod"
    managed_by  = "terraform"
  }
}
```

## NS Delegation Instructions

After applying the module, you'll receive AliCloud DNS nameservers in the output. You must update your domain registrar's NS records to delegate DNS to AliCloud.

### AliCloud DNS Nameservers

AliCloud typically assigns nameservers like:
```
ns1.alidns.com
ns2.alidns.com
```

The actual nameservers are provided in the `dns_servers` output.

### Registrar Configuration

#### GoDaddy
1. Sign in to your GoDaddy account
2. Go to My Products → Domains
3. Select your domain → DNS → Nameservers
4. Change to "Custom" nameservers
5. Enter the AliCloud nameservers from Terraform output
6. Save

#### Namecheap
1. Sign in to your Namecheap account
2. Go to Domain List → Manage
3. Select "Custom DNS" under Nameservers
4. Enter the AliCloud nameservers
5. Save (checkmark)

#### Cloudflare (if registered there)
1. Sign in to Cloudflare
2. Select your domain
3. Go to DNS → Records → Change Nameservers
4. Note: You may need to remove the domain from Cloudflare first

#### AWS Route 53 (if registered there)
1. Sign in to AWS Console
2. Go to Route 53 → Registered Domains
3. Select your domain → Add or edit name servers
4. Replace with AliCloud nameservers

### Verify Propagation

DNS propagation can take up to 48 hours. Verify with:

```bash
# Check NS records
dig NS example.com +short

# Expected output (after propagation):
# ns1.alidns.com.
# ns2.alidns.com.

# Or use nslookup
nslookup -type=NS example.com
```

You can also check propagation status at:
- https://www.whatsmydns.net/
- https://dnschecker.org/

## ExternalDNS Integration

This module creates the DNS zone that ExternalDNS can use to automatically manage records for Kubernetes workloads.

### Integration Flow

1. This module creates the public DNS zone for `example.com`
2. ExternalDNS (deployed as K8s addon) watches Ingress/Service resources
3. ExternalDNS creates/updates A/CNAME records in the zone automatically

### ExternalDNS Configuration

Configure ExternalDNS values to use this zone:

```yaml
provider: alibabacloud
alibabacloud:
  regionId: ap-southeast-1
  zoneType: public
domainFilters:
  - example.com  # Must match the domain_name of this module
policy: sync  # or "upsert-only" for safer operation
txtOwnerId: my-cluster
```

### Ingress Annotation Example

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app
  annotations:
    external-dns.alpha.kubernetes.io/hostname: app.example.com
spec:
  ingressClassName: nginx
  rules:
    - host: app.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-app
                port:
                  number: 80
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| domain_name | The domain name for the public DNS zone | `string` | n/a | yes |
| create_domain_group | Whether to create a new domain group | `bool` | `false` | no |
| domain_group_name | Name of the domain group | `string` | `null` | no |
| group_id | Existing domain group ID to use | `string` | `null` | no |
| remark | Remarks/description for the domain | `string` | `null` | no |
| records | List of DNS records to create | `list(object)` | `[]` | no |
| tags | Tags to apply to the DNS zone | `map(string)` | `{}` | no |

### Records Object

| Attribute | Description | Type | Default | Required |
|-----------|-------------|------|---------|:--------:|
| key | Unique key for this record (auto-generated as `type-rr` if not set) | `string` | `null` | no |
| rr | Host record ("@" for apex, "www", "api", "*" for wildcard) | `string` | n/a | yes |
| type | Record type (A, AAAA, CNAME, TXT, MX, NS, SRV) | `string` | n/a | yes |
| value | Record value (IP, hostname, or text) | `string` | n/a | yes |
| ttl | TTL in seconds (600-86400 for free tier) | `number` | `600` | no |
| priority | Priority for MX records (1-100) | `number` | `10` | no |
| status | Record status (ENABLE or DISABLE) | `string` | `"ENABLE"` | no |
| remark | Record description | `string` | `null` | no |

> **Note:** Use explicit `key` values when creating multiple records of the same type for the same subdomain (e.g., round-robin A records).

## Outputs

| Name | Description |
|------|-------------|
| domain_id | The ID of the DNS domain |
| domain_name | The domain name |
| dns_servers | List of AliCloud DNS nameservers for NS delegation |
| puny_code | Punycode for internationalized domain names |
| group_id | The domain group ID |
| group_name | The domain group name |
| domain_group_id | ID of created domain group (null if not created) |
| record_ids | Map of record keys to their IDs |
| records | Map of created DNS records with details |

## Supported Record Types

| Type | Description | Example Value |
|------|-------------|---------------|
| A | IPv4 address | `203.0.113.10` |
| AAAA | IPv6 address | `2001:db8::1` |
| CNAME | Canonical name (alias) | `www.example.com` |
| TXT | Text record | `v=spf1 include:_spf.google.com ~all` |
| MX | Mail exchange | `mail.example.com` (with priority) |
| NS | Nameserver | `ns1.example.com` |
| SRV | Service record | `0 5 5269 xmpp.example.com` |
| CAA | Certificate Authority Authorization | `0 issue "letsencrypt.org"` |

## Limitations

- Domain must be registered before adding to AliCloud DNS
- Each domain can only exist in one Alibaba Cloud account
- Free tier TTL range: 600-86400 seconds
- API rate limits apply - batch record changes when possible

## References

- [AliCloud DNS Documentation](https://www.alibabacloud.com/help/en/dns)
- [Terraform alicloud_alidns_domain](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs/resources/alidns_domain)
- [Terraform alicloud_alidns_record](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs/resources/alidns_record)
- [ExternalDNS AlibabaCloud Provider](https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/alibabacloud.md)
