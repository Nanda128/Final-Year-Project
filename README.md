# Nanda's FYP: Digital Twin Framework for Autonomous Drone Swarm Coordination in Maritime SAR Operations

This repository contains the code and resources for my Final Year Project at the University of Limerick.
I'm Nanda, a student enrolled in LM173 BSc Immersive Software Engineering, and this project focuses on developing a
digital twin framework to enhance the coordination of autonomous drone swarms in maritime search and rescue (SAR)
operations.

Below, I'll include an overview of the project, and a quick guide on how to run my project.

## Project Overview

Maritime Search and Rescue operations are critical for saving lives at sea, but they often face challenges such as vast
search areas, unpredictable weather conditions, and limited resources.
Autonomous drone swarms could potentially significantly improve the efficiency of SAR missions by providing rapid area
coverage, real-time data collection, and enhanced situational awareness.

I believe that the reliance of most SAR operations on manual coordination, volunteer labour, and machines like
Helicopters and Boats which are expensive to maintain full readiness with, can lead to mistakes and delays in critical
situations.
To address these challenges, I believe that making the use of Drone Swarms easier to manage might make these operations
cheaper, efficient, and effective.

The primary objective of this project is to develop a digital twin framework that simulates and manages the coordination
of autonomous drone swarms during maritime SAR missions.

## How to use and read LaTeX files

This project also represents my first time learning to use LaTeX, a typesetting system commonly used for technical and
scientific documentation.
To compile the LaTeX files in this repository, you will need a LaTeX distribution installed on your system, such as TeX
Live or MiKTeX.

For this project, I use MikTeX on Windows.
MikTex works for Windows, macOS, and Linux.
You can download it from https://miktex.org/download.

After installing a LaTeX distribution, you can use an editor like TeXstudio or Overleaf to open and compile the .tex
files in this repository.
I used IntelliJ IDEA with the TeXiFy plugin for writing and compiling my LaTeX documents.

To compile the main document, navigate to ``src/scripts`` and run either ``build_latex.ps1`` or ``build_latex.sh``
depending on your operating system.

(Run PowerShell (.ps1) script on Windows, or Bash (.sh) script on Linux/macOS)

### Why use LaTeX?

I chose to use LaTeX for this project because it made easier to manage citations with BibTex, looked professional, and
above all, could be version-controlled easier.
Word's version control system is rudimentary at best, and I found it difficult to manage changes and revisions across my
devices.

## Template Folder

``src/IEEEtran/`` contains the IEEEtran LaTeX template files that I used for formatting my report according to IEEE
standards.
I'll keep it there for reference, on how to format documents in IEEE style.
I'll remove it, and this section, once the project is complete.
