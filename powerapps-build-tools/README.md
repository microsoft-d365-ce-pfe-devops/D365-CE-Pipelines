
## PowerApps Build Tools multi-stage YAML Pipelines

PowerApps Build Tools is a first-party set of common build and deployment tasks for Dynamics 365 Customer Engagement. If you are interested in learning to use the toolset using the classic editor check out the labs at http://aka.ms/ppalmlab for more information.

Requirements:
 - Install [PowerApps Build Tools](https://marketplace.visualstudio.com/items?itemName=microsoft-IsvExpTools.PowerApps-BuildTools) in your Azure DevOps organization.

To get started you will need to create three service connections. For more information check out the [Service connection: Create a service connection](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/service-endpoints?view=azure-devops&tabs=yaml#create-a-service-connection) documentation.
1. GitHub
2. build environment - See ***build-with-jit.yml explained.*** below.
3. target environment - this is any downstream environment you wish to deploy to.

### build-with-jit.yml explained

If you followed along with the labs found at http://aka.ms/ppalmlab you will have noticed the use of an environment during the build process to produce a managed solution artifact. During the build process, an unmanaged solution is packed from source control, imported into a build environment that if successful, then exports a managed artifact for deployment to downstream environments. Following this same flow, a YAML template has been created to support this process.

### Additional notes
This example setup does not have gating at any point. To add gating to your deployments check out [Environment checks](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/approvals?view=azure-devops.
