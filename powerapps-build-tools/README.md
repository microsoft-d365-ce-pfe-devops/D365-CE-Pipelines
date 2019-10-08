
## PowerApps Build Tools multi-stage YAML Pipelines

PowerApps Build Tools is a first-party set of common build and deployment tasks for Dynamics 365 Customer Engagement. If you are interested in learning to use the tool set using the classic editor check out the labs at http://aka.ms/ppalmlab for more information.

Requirements:
 - Install [PowerApps Build Tools](https://marketplace.visualstudio.com/items?itemName=microsoft-IsvExpTools.PowerApps-BuildTools) in you Azure DevOps organization.

To get started you will need to create three service connections.For more information check out the [Service connection: Create a service connection](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/service-endpoints?view=azure-devops&tabs=yaml#create-a-service-connection) documentation.
1. GitHub
2. build environment - See ***build-with-jit.yml explained.*** below.
3. target environment - this is any downstream environment you wish to deploy to.

### build-with-jit.yml explained

If you followed along with the labs found at http://aka.ms/ppalmlab you will have noticed the use of an environment during the build process to produce a managed solution artifact. During the build process an unmanaged solution is packed from source control, imported into a build environment that if successful, then exports a managed artifact for deployment to downstream environments. Following this same flow a YAML template has been created to support this process.

### Usage example

Orchestrating the templates found under the powerapps-build-tools directory can be accomplished using the example code below. 

```yaml
name: $(BuildDefinitionName)-$(Date:yyyyMMdd).$(Rev:.r)

resources:
  repositories:
    - repository: templates
      type: GitHub
      name: microsoft-d365-ce-pfe-devops/D365-CE-Pipelines
      endpoint: GitHub
      # ref: refs/heads/master # optionally pin to a branch
      # ref: refs/tags/v1.0 # optionaly pin to a tag

stages:
  - template: powerapps-build-tools/stages/build-with-jit.yml@templates
    parameters:
      name: 'Build_Test_Solution'
      vmImage: 'vs2017-win2016'
      buildEnvironment: 'contoso-build'
      solutionName: '$(solution.name)'
      solutionPath: '$(solution.path)'
  - template: powerapps-build-tools/stages/release.yml@templates
    parameters:
      name: 'Release'
      dependsOn: 'Build_Test_Solution'
      vmImage: 'vs2017-win2016'
      targetEnvironment: 'contoso-production'
      solutionName: '$(solution.name)'
```

Templated stages have been built with parameters so that setting can be defined in an Azure Pipeline setup in your Azure DevOps project. 

In this example, we have two variables defined, everything else is hard-coded, you are free to update this script to meet your needs or extend functionality.

### Required Variables
 - solution.name -- The *name* of your solution as seen in the [Maker portal](https://make.powerapps.com/environments/environment:solutions/solutions). example: contoso-plugins
 - solution.path -- Path is determined from the repositories root directory. Example: unpacked-solutions
 
