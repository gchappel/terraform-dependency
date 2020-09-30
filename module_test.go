package repro

import (
	"os"
	"os/exec"
	"testing"
	"regexp"
	"strings"

	"github.com/gruntwork-io/terratest/modules/files"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestModule(t *testing.T) {
	t.Parallel()
	uniqueID := strings.ToLower(random.UniqueId())
	versionRegex := regexp.MustCompile(`v\d\.\d{2}\.\d{1,2}`)
	version, _ := exec.Command("terraform", "-version").Output()
	tempTerraformDir, _ := files.CopyTerraformFolderToTemp("./", "idempotency")
	defer os.RemoveAll(tempTerraformDir)
	logger.Logf(t, "Running Terraform from %s", tempTerraformDir)
	logger.Logf(t, "Terraform version: %s", versionRegex.Find([]byte(version)))
	logger.Logf(t, "unique ID for this run is: %s", uniqueID)
	terraformOptions := &terraform.Options{
		TerraformDir: tempTerraformDir,
		Vars: map[string]interface{}{
			"unique_id": uniqueID,
			"resource_group_name": "edit-me", // EDIT ME
		},
	}
	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndPlan(t, terraformOptions)
	terraform.InitAndApplyAndIdempotent(t, terraformOptions)
}