# Elixir in Action - Comprehensive Learning Curriculum

A complete, progressive learning curriculum for mastering Elixir programming through hands-on exercises, concept drills, integration challenges, and real-world capstone projects based on **"Elixir in Action, 3rd Edition"** by Saša Jurić (Manning Publications, 2024).

## 📚 About This Curriculum

This repository provides a comprehensive, chapter-by-chapter learning path from Elixir fundamentals through advanced concurrent programming, distributed systems, and production-ready applications. Each chapter includes structured learning materials with practical exercises that build progressively toward mastery of the BEAM ecosystem.

> **⚠️ Copyright Notice:** PDF files from "Elixir in Action" have been omitted from this repository to respect copyright law. You must obtain your own legal copy of the book from [Manning Publications](https://www.manning.com/books/elixir-in-action-third-edition). This repository contains only original learning materials, exercises, and organizational tools designed to complement the official book.

## 🎯 Complete Curriculum (Chapters 1-13)

### ✅ All Chapters Complete

**355KB of comprehensive learning material** covering all 13 chapters with progressive difficulty and real-world applications.

## 📂 Repository Structure

```
.
├── Exercises/                                 # ⭐ MAIN CURRICULUM (Chapters 1-13)
│   ├── chapter_01.md                          # First Steps (15KB)
│   ├── chapter_02.md                          # Building Blocks (23KB)
│   ├── chapter_03.md                          # Control Flow (29KB)
│   ├── chapter_04.md                          # Data Abstractions (33KB)
│   ├── chapter_05.md                          # Concurrency Primitives (26KB)
│   ├── chapter_06.md                          # GenServer (27KB)
│   ├── chapter_07.md                          # Building Systems (31KB)
│   ├── chapter_08.md                          # Fault Tolerance (23KB)
│   ├── chapter_09.md                          # Supervision Trees (39KB)
│   ├── chapter_10.md                          # Beyond GenServer (33KB)
│   ├── chapter_11.md                          # OTP Applications (28KB)
│   ├── chapter_12.md                          # Distributed Systems (22KB)
│   ├── chapter_13.md                          # Running the System (26KB)
│   └── README.md                              # Exercise guide
├── SOLUTION/                                  # Reference solutions
├── data/
│   ├── TXT/                                   # Book chapter text (extracted)
│   └── Elixir_in_Action_Third_Edition.json   # Book metadata
├── .devcontainer/                             # Docker development environment
├── do.ipynb                                   # PDF extraction utility
└── README.md                                  # This file
```

## 📖 Learning Path

### Part 1: Foundations (Chapters 1-4)

**🎯 Build a solid foundation in Elixir fundamentals**

- **Chapter 1: First Steps** (15KB)
  - Elixir basics, BEAM VM, interactive shell
  - Functions, modules, basic data types
  - Pattern matching introduction
  - **Project:** Calculator module with pattern matching

- **Chapter 2: Building Blocks** (23KB)
  - Data types: lists, tuples, maps, structs
  - Operators and basic functions
  - Immutability and transformation
  - **Project:** Contact list manager

- **Chapter 3: Control Flow** (29KB)
  - Pattern matching, guards, multiclause functions
  - Recursion and tail-call optimization
  - Enum and Stream for iteration
  - Comprehensions
  - **Capstone:** Log File Analyzer

- **Chapter 4: Data Abstractions** (33KB)
  - Module-based abstractions
  - Structs with behavior
  - Protocols for polymorphism
  - Hierarchical data with maps
  - **Capstone:** Library Management System

### Part 2: Concurrent Elixir (Chapters 5-10)

**🎯 Master concurrent programming and OTP behaviors**

- **Chapter 5: Concurrency Primitives** (26KB)
  - Process spawning and message passing
  - Stateful server processes
  - Process registration and discovery
  - **Capstone:** Concurrent HTTP Pool

- **Chapter 6: Generic Server Processes** (27KB)
  - GenServer behavior
  - Callbacks: init, handle_call, handle_cast, handle_info
  - Synchronous vs asynchronous patterns
  - **Capstone:** Distributed Key-Value Store

- **Chapter 7: Building a Concurrent System** (31KB)
  - Mix projects and applications
  - Multi-process architectures
  - Todo server implementation
  - **Capstone:** Complete Todo System

- **Chapter 8: Fault-Tolerance Basics** (23KB)
  - Error types and handling
  - Links and monitors
  - Supervisor basics
  - **Capstone:** Fault-Tolerant HTTP Client

- **Chapter 9: Isolating Error Effects** (39KB)
  - Supervision trees and strategies
  - Registry for process discovery
  - DynamicSupervisor for on-demand processes
  - "Let it crash" philosophy
  - **Capstone:** Resilient Task Queue System

- **Chapter 10: Beyond GenServer** (33KB)
  - Task for one-off computations
  - Agent for simple state
  - ETS tables for high-performance storage
  - **Capstone:** Distributed Job Queue with Metrics

### Part 3: Production Systems (Chapters 11-13)

**🎯 Deploy and maintain production Elixir applications**

- **Chapter 11: Working with Components** (28KB)
  - OTP applications structure
  - Managing dependencies with Mix
  - Building web servers with Plug/Cowboy
  - Application configuration
  - **Capstone:** Production Web Application (Blog API)

- **Chapter 12: Building a Distributed System** (22KB)
  - Starting and connecting nodes
  - Global process registration
  - Process groups with :pg
  - Distributed links and monitors
  - Network considerations
  - **Capstone:** Fault-Tolerant Distributed Chat

- **Chapter 13: Running the System** (26KB)
  - Running with Mix and Elixir tools
  - Building OTP releases
  - Runtime configuration
  - Remote debugging and monitoring
  - Observer and system introspection
  - **Capstone:** Production Monitoring Dashboard

## 🎓 Each Chapter Includes

### 1. Chapter Summary (2-3 sentences)
High-level overview highlighting key concepts and learning outcomes.

### 2. Concept Drills (5-7 exercises)
Short, focused exercises on isolated skills:
- Clear learning objectives
- Step-by-step instructions
- Expected outputs and behavior
- Success criteria
- Range from basic to intermediate difficulty

### 3. Integration Exercises (3-5 exercises)
Medium-complexity challenges combining multiple concepts:
- Explicitly state which prior concepts are reinforced
- Build on previous chapters progressively
- Clear deliverables and success criteria
- Real-world application scenarios

### 4. Capstone Project (1 substantial project)
Production-style application demonstrating chapter mastery:
- Complete project description
- Detailed requirements and architecture
- Multiple features to implement
- Bonus challenges for extension
- Comprehensive evaluation criteria

### 5. Success Checklist
Self-assessment questions before moving to the next chapter.

### 6. Looking Ahead
Preview of the next chapter's concepts and how they build on current knowledge.

## 🚀 Getting Started

### Prerequisites

- **A legal copy of "Elixir in Action, 3rd Edition"** - [Purchase from Manning](https://www.manning.com/books/elixir-in-action-third-edition)
- **Elixir 1.14+** and **Erlang/OTP 25+** installed ([Installation Guide](https://elixir-lang.org/install.html))
- Basic programming knowledge (any language)
- Text editor or IDE (VS Code recommended with ElixirLS extension)

### Quick Start

1. **Clone the repository:**
   ```bash
   git clone <your-repository-url>
   cd elixir-in-action-curriculum
   ```

2. **Start with Chapter 1:**
   ```bash
   # Open the first chapter exercises
   cat Exercises/chapter_01.md
   ```

3. **Work through systematically:**
   - Read the corresponding chapter in your book
   - Review the chapter summary and exercises
   - Complete the concept drills
   - Work through integration exercises
   - Build the capstone project
   - Verify with the success checklist

### Recommended Learning Workflow

```bash
# 1. Read the book chapter first

# 2. Review the exercise file
cat Exercises/chapter_X.md

# 3. Complete drills in IEx
iex

# 4. Build integration exercises
mix new chapter_X_integration
cd chapter_X_integration
iex -S mix

# 5. Create capstone project
mix new chapter_X_capstone --sup
cd chapter_X_capstone

# 6. Test and verify
mix test
```

## 🛠️ Development Environment

### Using the Development Container

For a consistent environment with all dependencies pre-configured:

1. **Install Prerequisites:**
   - [Docker Desktop](https://www.docker.com/products/docker-desktop)
   - [VS Code](https://code.visualstudio.com/) with [Remote-Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

2. **Open in Container:**
   ```bash
   code .
   # VS Code will prompt to reopen in container
   ```

The container includes:
- **Elixir 1.19.4** with OTP 27 and Phoenix 1.8.3
- **Python 3** with Jupyter and PDF processing tools
- **Node.js 20 LTS** for Phoenix LiveView
- **PostgreSQL client** for database development
- **VS Code extensions** for Elixir, Python, and Jupyter

## 📊 Curriculum Statistics

- **Total Content:** 355KB across 13 comprehensive chapters
- **Total Exercises:** 100+ hands-on exercises and projects
- **Concept Drills:** 70+ focused skill-building exercises
- **Integration Challenges:** 50+ multi-concept exercises
- **Capstone Projects:** 13 substantial real-world applications
- **Progressive Difficulty:** From basics to production deployment

## 💡 Learning Methodology

### Progressive Difficulty

- **Chapters 1-2:** Pure fundamentals, no prior knowledge required
- **Chapters 3+:** Each exercise incorporates at least one concept from previous chapters
- **Chapters 4+:** Capstone projects build on previous capstone projects
- **Chapters 9+:** Production-ready patterns and distributed systems

### Key Learning Principles

1. **Type Everything Yourself** - Build muscle memory, don't copy-paste
2. **Experiment Actively** - Modify examples to understand behavior
3. **Use IEx Extensively** - The interactive shell is your laboratory
4. **Read Error Messages** - Elixir's errors are informative and helpful
5. **Build Progressively** - Each chapter builds on previous concepts
6. **Test Your Code** - Write tests as you learn
7. **Think in Processes** - Embrace the concurrent mindset
8. **Draw Diagrams** - Visualize supervision trees and process communication

## 🎯 Capstone Project Progression

The capstone projects build progressively toward a production-ready distributed system:

1. **Ch 1-2:** Basic modules and data structures
2. **Ch 3:** Log File Analyzer (pattern matching, streams)
3. **Ch 4:** Library Management System (protocols, abstractions)
4. **Ch 5:** Concurrent HTTP Pool (processes, message passing)
5. **Ch 6:** Distributed KV Store (GenServer, replication)
6. **Ch 7:** Complete Todo System (multi-process architecture)
7. **Ch 8:** Fault-Tolerant HTTP Client (supervision, recovery)
8. **Ch 9:** Resilient Task Queue (supervision trees, isolation)
9. **Ch 10:** Job Queue with Metrics (Tasks, ETS, monitoring)
10. **Ch 11:** Production Web API (OTP app, dependencies)
11. **Ch 12:** Distributed Chat System (clustering, replication)
12. **Ch 13:** Production Monitoring (releases, debugging)

## 📚 Additional Resources

### Official Documentation
- [Elixir Documentation](https://elixir-lang.org/docs.html)
- [Elixir Getting Started Guide](https://elixir-lang.org/getting-started/introduction.html)
- [HexDocs](https://hexdocs.pm/elixir)
- [Erlang Documentation](https://www.erlang.org/docs)

### Community
- [Elixir Forum](https://elixirforum.com/)
- [Elixir Slack](https://elixir-slackin.herokuapp.com/)
- [ElixirConf Videos](https://www.youtube.com/@ElixirConf)
- [Elixir Radar Newsletter](https://elixir-radar.com/)

### Tools
- **IEx** - Interactive Elixir shell
- **Mix** - Build tool and project manager
- **ExUnit** - Built-in testing framework
- **Observer** - Process visualization (`:observer.start()`)
- **Dialyzer** - Static analysis tool

### Practice Platforms
- [Exercism Elixir Track](https://exercism.org/tracks/elixir)
- [Elixir School](https://elixirschool.com/)
- [Advent of Code](https://adventofcode.com/) (solve in Elixir)

## 🤝 Contributing

Contributions are welcome! Areas for contribution:

- Additional practice exercises
- Alternative solution approaches
- Real-world project extensions
- Bug fixes and clarifications
- Testing strategies and examples

### How to Contribute

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/improvement`)
3. Commit your changes (`git commit -am 'Add drill for Chapter X'`)
4. Push to the branch (`git push origin feature/improvement`)
5. Open a Pull Request

## 📄 License and Copyright

This curriculum's original content (exercises, drills, project specifications) is released under the MIT License. See [LICENSE](LICENSE) for details.

**Copyright Compliance:**
- "Elixir in Action, 3rd Edition" © 2024 Manning Publications
- Book content is NOT included in this repository
- PDF files and book text are excluded from version control
- **You must purchase the book legally** from [Manning Publications](https://www.manning.com/books/elixir-in-action-third-edition)
- This repository provides supplementary materials to be used alongside the official book

**Please support author Saša Jurić and Manning Publications by purchasing the book.**

## 🙏 Acknowledgments

- **Saša Jurić** - Author of "Elixir in Action"
- **Manning Publications** - Publisher
- **Elixir Core Team** - For creating an amazing language and ecosystem
- **Elixir Community** - For extensive documentation, libraries, and support

## 🎓 Learning Outcomes

By completing this curriculum, you will be able to:

✅ Write idiomatic, functional Elixir code
✅ Build concurrent, scalable applications
✅ Design fault-tolerant systems with OTP
✅ Create production-ready web applications
✅ Deploy distributed systems across multiple nodes
✅ Monitor and debug production BEAM systems
✅ Understand BEAM VM internals and optimization
✅ Apply "let it crash" philosophy effectively

---

## 🚀 Start Your Journey

**Ready to begin?** Open `Exercises/chapter_01.md` and start building your Elixir expertise today!

```bash
cat Exercises/chapter_01.md
```

**The best way to learn Elixir is to write Elixir. Let it crash, and learn from the experience!** 🎉

---

**Created:** January 2026
**Based on:** "Elixir in Action, 3rd Edition" by Saša Jurić
**Format:** Progressive exercises with capstone projects
**Status:** ✅ Complete (Chapters 1-13)
