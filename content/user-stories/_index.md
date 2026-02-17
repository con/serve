---
title: "User Stories"
date: 2026-02-16
description: "Concrete archival scenarios that drive con/serve development — from personal digital vaults to lab-wide research infrastructure"
cascade:
  showEdit: true
---

The [Tools](/tools/) section catalogs what exists.
The [Concepts](/concepts/) section describes how the pieces fit together.
This section describes **why** -- the concrete scenarios
that motivate the development of tools, connectors, and workflows.

Each user story represents a real archival goal
that a person or research group would pursue.
Stories identify the data sources, the desired end state,
the tools involved, and the gaps that need to be filled.

## Stories

**[Personal Archive](personal-archive/)** --
Build a comprehensive personal digital archive from a Google account,
photo collections, personal messaging channels, YouTube subscriptions,
and other personal data sources.
The single largest archival project most individuals will undertake.

**[Neuroimaging Lab](neuroimaging-lab/)** --
A research lab running MRI experiments with ReproIn-convention DICOMs,
ReproStim stimulus capture, CurDes BIRCH behavioral events,
Slack for communication, and GitHub for processing code.
Data flows through HeuDiConv into BIDS,
then MRIQC and fMRIPrep for preprocessing.

**[Brain Imaging Center](brain-imaging-center/)** --
A shared MRI facility serving multiple labs:
collecting DICOMs with ReproIn conventions,
running weekly phantom QA to monitor scanner health,
recording environmental conditions,
capturing stimuli and events for all experiments,
and providing streamlined preprocessing via HPC.

**[Software Project](software-project/)** --
An open-source project on GitHub (prototypical target: DANDI)
needs to archive all forge artifacts -- repositories, issues, PRs,
Actions logs, Discussions -- alongside Slack communications,
with a Forgejo-Aneksajo mirror using GitHub authentication.
