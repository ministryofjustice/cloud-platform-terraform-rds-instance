package main

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

func Test(t *testing.T) {

	terraformOptionsVpc := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "./unit-test",
		Targets: []string{"module.vpc"},
	})

	terraform.InitAndApply(t, terraformOptionsVpc)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "./unit-test",
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

}
