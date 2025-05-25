# OpenTofu AWS Modules

## Initialization
To initialize the project, run the following command:

```
tofu init
```

## Planning
To create a plan file, execute:

```
tofu plan -out=tfplan
```
This will generate a `tfplan` file.

## Applying Configuration
To apply the configuration, use:

```
tofu apply tfplan
```

## Destroying Resources
For destroying resources, run:

```
tofu destroy --auto-approve
```