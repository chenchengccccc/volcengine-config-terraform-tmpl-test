# Preflight atomicity switch

This fixture is temporarily switched among provider-free, TerraformCC IAM, and invalid HCL states during BOE CreateRule, UpdateRule, and EnableRule atomicity regression. Keep the checked-in final state valid and provider-free after each run.
