# Contributing

:+1::tada: Thank you for taking the time to help advance education in the FPGA emulation field. :tada::+1:

The following is a set of guidelines for contributing our site, which is hosted in the [FPGAEmu Repo](https://github.com/fpgaemu/fpgaemu) on GitHub. These are mostly guidelines, not rules. Use your best judgment, and feel free to propose changes to this document in a pull request. Note &mdash; this contributing document is adapted from the [Atom Organization](https://github.com/atom).

#### Table Of Contents

[Code of Conduct](#code-of-conduct)

[Questions?](#questions)

[What should I know before I get started?](#what-should-i-know-before-i-get-started)
  * [Mission Statement](#mission-statement)

[How Can I Contribute?](#how-can-i-contribute)
  * [Reporting Bugs](#reporting-bugs)
  * [Suggesting Enhancements](#suggesting-enhancements)
  * [Pull Requests](#pull-requests)

[Styleguides](#styleguides)
  * [Git Commit Messages](#git-commit-messages)
  * [JavaScript Styleguide](#javascript-styleguide)
  * [Verilog Styleguide](#verilog-styleguide)
  * [Documentation Styleguide](#documentation-styleguide)

## Code of Conduct

This project and everyone participating in it is governed by the [Code of Conduct](CODE_OF_CONDUCT.md), adapted from the CoC provided by the [Contributor Covenant Organization](https://contributor-covenant.org) By participating, you are expected to uphold this code. 

## Questions?

> **Note:** We are a very small team, so expect an extended waiting period if we are unable to respond immediately. Apologies in advance.

Have any questions about contributing or the project in general? Feel free to file an issue or contact the primary repo maintainer at [chadmondwu@gmail.com](mailto:chadmondwu@gmail.com).

## What should I know before I get started?

### Mission Statement

This project's objective is to provide a beginner-oriented look into the complex field of FPGA and hardware emulation &mdash; one that traditionally necessitates an MS in EE/CE. We develop our website under the assumption that the majority of those reading will have at a minimum some experience in electrical engineering/computer science. As such, we strive to create an education that is as accessible as possible, making our content interesting for those with a passing interest, experts with extensive experience, and everyone in between.

## How Can I Contribute?

### Reporting Bugs

This section guides you through submitting a bug report. Following these guidelines helps maintainers and the community understand your report :pencil:, reproduce the behavior :computer: :computer:, and find related reports :mag_right:.

Before creating bug reports, please check [this list](#before-submitting-a-bug-report) as you might find out that you don't need to create one. When you are creating a bug report, please [include as many details as possible](#how-do-i-submit-a-good-bug-report). Check out the three issue templates we have provided for a running start.

> **Note:** If you find a **Closed** issue that seems like it is the same thing that you're experiencing, open a new issue and include a link to the original issue in the body of your new one.

#### Before Submitting A Bug Report

* **Check the [Xilinx Forums](https://forums.xilinx.com).** Issues arise with synthesis, implementation, and bitstream generation all the time, especially across multiple Vivado versions and varying host/board hardware. We will attempt to list all issues that we come across, but since we will be primarily working with old Xilinx hardware, chances are that any additional bugs that may arise can be or already have been answered by the experts on Xilinx's forums. That being said, please do not spam them with any and all of your bugs, they really are a nice group of people.
* **Be sure to also check the [HW/SW FAQs on the forum](https://forums.xilinx.com/t5/Forums/ct-p/XlnxProd)** for a list of common questions and problems.
* **Perform a [cursory search](https://github.com/search?q=+is%3Aissue+user%3Achadmondwu)** to see if the problem has already been reported. If it has **and the issue is still open**, add a comment to the existing issue instead of opening a new one.

#### How Do I Submit A (Good) Bug Report?

Bugs are tracked as [GitHub issues](https://guides.github.com/features/issues/). After determining the relevant problem, please follow the guidelines bellow. Verilog and Vivado are relatively complex (and buggy!) so the more information, the better.

Explain the problem and include additional details to help maintainers reproduce the problem:

* **Use a clear and descriptive title** for the issue to identify the problem.
* **Describe the exact steps which reproduce the problem** in as many details as possible. For example, start by explaining how you started Vivado, e.g. which command exactly you used in the TCL terminal, or which prompt did you select in the GUI. 
* **Provide specific examples to demonstrate the steps**. Include links to files or GitHub projects, or copy/pasteable snippets, which you use in those examples. If you're providing snippets in the issue, especially for Verilog/SystemVerilog files, use [Markdown code blocks](https://help.github.com/articles/markdown-basics/#multiple-lines).
* **Describe the behavior you observed after following the steps** and point out what exactly is the problem with that behavior.
* **Explain which behavior you expected to see instead and why.**
* **Include screenshots and animated GIFs** which show you following the described steps and clearly demonstrate the problem. You can use [this tool](https://www.cockos.com/licecap/) to record GIFs on macOS and Windows, and [this tool](https://github.com/colinkeenan/silentcast) or [this tool](https://github.com/GNOME/byzanz) on Linux.
* **If the problem wasn't triggered by a specific action**, describe what you were doing before the problem happened and share more information using the guidelines below.

Provide more context by answering these questions:

* **Can you reproduce the problem in [safe mode](https://flight-manual.atom.io/hacking-atom/sections/debugging/#diagnose-runtime-performance-problems-with-the-dev-tools-cpu-profiler)?**
* **Did the problem start happening recently** (e.g. after updating to a new version of Vivado) or was this always a problem?
* If the problem started happening recently, **can you reproduce the problem in an older version of Vivado?** What's the most recent version in which the problem doesn't happen? You can download older versions of Vivado from [the downloads archive](https://xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools/archive.html).
* **Can you reliably reproduce the issue?** If not, provide details about how often the problem happens and under which conditions it normally happens.

Include details about your configuration and environment:

* **Which version of Vivado are you using?** You can get the exact version by running `version` in your TCL console, or in the GUI by selecting the Help -> About menu.
* **What's the name and version of the OS you're using**? Missing packages can cause issues with Vivado installation, so check your distro if you are running Linux. Note that Vivado does not support macOS natively.
* **Are you running Vivado in a virtual machine?** If so, which VM software are you using and which operating systems and versions are used for the host and the guest?
* **Which keyboard layout are you using?** Are you using a US layout or some other layout?

### Suggesting Enhancements

This section guides you through submitting an enhancement suggestion for our site, including completely new features and minor improvements to existing functionality. Following these guidelines helps maintainers and the community understand your suggestion :pencil: and find related suggestions :mag_right:.

Before creating enhancement suggestions, please check [this list](#before-submitting-an-enhancement-suggestion) as you might find out that you don't need to create one. When you are creating an enhancement suggestion, please [include as many details as possible](#how-do-i-submit-a-good-enhancement-suggestion).

#### Before Submitting An Enhancement Suggestion

* **Perform a [cursory search](https://github.com/search?q=+is%3Aissue+user%3Achadmondwu)** to see if the enhancement has already been suggested. If it has, add a comment to the existing issue instead of opening a new one.

#### How Do I Submit A (Good) Enhancement Suggestion?

Enhancement suggestions are tracked as [GitHub issues](https://guides.github.com/features/issues/). After you've determined which repo your enhancement suggestion is related to, create an issue on that repository and provide the following information:

* **Use a clear and descriptive title** for the issue to identify the suggestion.
* **Provide a step-by-step description of the suggested enhancement** in as many details as possible.
* **Provide specific examples to demonstrate the steps**. Include copy/pasteable snippets which you use in those examples, as [Markdown code blocks](https://help.github.com/articles/markdown-basics/#multiple-lines).
* **Describe the current behavior** and **explain which behavior you expected to see instead** and why.
* **Include screenshots and animated GIFs** which help you demonstrate the steps or point out the part of our site or Verilog code which the suggestion is related to. You can use [this tool](https://www.cockos.com/licecap/) to record GIFs on macOS and Windows, and [this tool](https://github.com/colinkeenan/silentcast) or [this tool](https://github.com/GNOME/byzanz) on Linux.
* **Explain why this enhancement would be useful** to implement in the future. 
* **Specify which version of Atom you're using.** You can get the exact version by running `version` in your TCL console, or in the GUI by selecting the Help -> About menu.
* **Specify the name and version of the OS you're using.**

### Pull Requests

The process described here has several goals:

- Maintain this project's quality
- Fix problems that are important to users
- Engage the community in working toward the best possible education that we can provide

Please follow these steps to have your contribution considered by the maintainers:

1. Follow all instructions in [the template](PULL_REQUEST_TEMPLATE.md)
2. Follow the [styleguides](#styleguides)
3. After you submit your pull request, verify that all [status checks](https://help.github.com/articles/about-status-checks/) are passing <details><summary>What if the status checks are failing?</summary>If a status check is failing, and you believe that the failure is unrelated to your change, please leave a comment on the pull request explaining why you believe the failure is unrelated. A maintainer will re-run the status check for you. If we conclude that the failure was a false positive, then we will open an issue to track that problem with our status check suite.</details>

While the prerequisites above must be satisfied prior to having your pull request reviewed, the reviewer(s) may ask you to complete additional design work, tests, or other changes before your pull request can be ultimately accepted.

## Styleguides

### Git Commit Messages

* Use the present tense ("Add feature" not "Added feature")
* Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
* Limit the first line to 72 characters or less
* Reference issues and pull requests liberally after the first line
* When only changing documentation, include `[ci skip]` in the commit title
* Consider starting the commit message with an applicable emoji:
    * :art: `:art:` when improving the format/structure of the code
    * :racehorse: `:racehorse:` when improving performance
    * :non-potable_water: `:non-potable_water:` when plugging memory leaks
    * :memo: `:memo:` when writing docs
    * :penguin: `:penguin:` when fixing something on Linux
    * :apple: `:apple:` when fixing something on macOS
    * :checkered_flag: `:checkered_flag:` when fixing something on Windows
    * :bug: `:bug:` when fixing a bug
    * :fire: `:fire:` when removing code or files
    * :green_heart: `:green_heart:` when fixing the CI build
    * :white_check_mark: `:white_check_mark:` when adding tests
    * :lock: `:lock:` when dealing with security
    * :arrow_up: `:arrow_up:` when upgrading dependencies
    * :arrow_down: `:arrow_down:` when downgrading dependencies
    * :shirt: `:shirt:` when removing linter warnings

### JavaScript Styleguide

* To revise in the future

### Verilog Styleguide
* To revise in the future

#### Example

```coffee
describe 'a dog', ->
 it 'barks', ->
 # spec here
 describe 'when the dog is happy', ->
  it 'wags its tail', ->
  # spec here
```

### Documentation Styleguide

* Use [Markdown](https://daringfireball.net/projects/markdown).
* Reference methods and classes in markdown with the custom `{}` notation:
    * To revise in the future-

#### Example

```coffee
# Public: Disable the package with the given name.
#
# * `name`    The {String} name of the package to disable.
# * `options` (optional) The {Object} with disable options (default: {}):
#   * `trackTime`     A {Boolean}, `true` to track the amount of time taken.
#   * `ignoreErrors`  A {Boolean}, `true` to catch and ignore errors thrown.
# * `callback` The {Function} to call after the package has been disabled.
#
# Returns `undefined`.
disablePackage: (name, options, callback) ->
```


