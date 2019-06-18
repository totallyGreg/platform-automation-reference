## GCP Environment Promotion Steps

- `./promote.sh sbx <target environment>`

This will copy all the files that are safe to promote to the new environment folder.  After copying these files it will try to interpolate.  If this interpolation fails add the variables the expect files using `sbx` as a template

### Operations Manager configuration
  - common-director/opsman.yml
  - `${environment}`/config-director/vars/infra.yml
  - `${environment}`/config-director/vars/opsman.yml
  - `${environment}`/config-director/secrets/opsman.yml

### Director configuration
  - common-director/director.yml
  - `${environment}`/config-director/vars/infra.yml
  - `${environment}`/config-director/vars/director.yml
  - `${environment}`/config-director/secrets/director.yml

#### Validate

  - `./validate-opsman-config.sh <product> [sbx/non-prod]`

### Tile configuration

#### Generate

You will generate the tile configuration for a given product by first placing the version file for that product in `${environment}/config/versions/${product}.yml` where product must match the tile product not the pivnet slug (cf vs elastic-runtime).

- `./generate-config.sh <product>`

This will also generate an empty <product>-operations file in this directory. Update that file with the operations files that are currently params in the pipline and re-run `./generate-config.sh`

#### Validate

Configuration is validated for completeness by using the following files

- `${environment}`/config/defaults/<product>.yml
- common/<product>.yml
- `${environment}`/config/vars/<product>.yml
- `${environment}`/config/secrets/<product>.yml

- `./validate-config.sh <product> [sbx/non-prod]`
