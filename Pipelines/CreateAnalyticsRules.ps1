# Analytics Rules build and deploy pipeline
# This pipeline publishes the rules file as an artifact and then uses a powershell task to deploy

parameters:
- name: customer
  displayName: Customer
  type: string
  default: No-Selection
  values:
  - Coller_Capital
  - Mizuho_International
  - DAC_Beachcroft
  - Gov_of_Jersey
  - Park_Square_Capital
  - 3i_Group
  - C5_Capital
  - Essentra
  - Oxera_Consulting
  - Doctors_Laboratory
  - ITC_Secure
  - Annington
  - No-Selection

name: build and deploy Alert Rules
resources:
 pipelines:
   - pipeline: Scripts
     source: 'scriptsCI'
trigger: 
 paths:
   include:
     - NonCommonAnalyticsRules/* 

stages:
- stage: build_alert_rules

  jobs:
    - job: AgentJob
      pool:
       name: Azure Pipelines
       vmImage: 'vs2017-win2016'
      steps:
       - task: CopyFiles@2
         displayName: 'Copy Alert Rules'
         inputs:
          SourceFolder: NonCommonAnalyticsRules/${{parameters.customer}}
          TargetFolder: '$(Pipeline.Workspace)'
       - task: Files-Validator@1
         inputs:
           rootDir: '$(Pipeline.Workspace)/*.json'
           validateXML: false
           validateJSON: true
           validateYAML: false
           validatePS: false
       - task: PublishBuildArtifacts@1
         displayName: 'Publish Artifact: RulesFile'
         inputs:
          PathtoPublish: '$(Pipeline.Workspace)'
          ArtifactName: RulesFile

- stage: Deploy_${{parameters.customer}}
  jobs:
    - job: AgentJob
      pool:
       name: Azure Pipelines
       vmImage: 'windows-2019'
      variables: 
      - group: ${{parameters.customer}}
      steps:
      - download: current
        artifact: RulesFile
      - download: Scripts
        patterns: '*.ps1'
      - task: AzurePowerShell@4
        displayName: 'Create and Update Alert Rules'
        inputs:
         azureSubscription: '${{parameters.customer}}'
         ScriptPath: '$(Pipeline.Workspace)/Scripts/Scripts/CreateAnalyticsRules.ps1'
         ScriptArguments: '-Workspace $(Workspace)'
         azurePowerShellVersion: LatestVersion
         pwsh: true