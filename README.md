# Elixir in Action Workbook

A comprehensive learning workbook for mastering Elixir programming through hands-on exercises, concept drills, and real-world projects based on **"Elixir in Action, 3rd Edition"** by Saša Jurić (Manning Publications, 2024).

## About This Workbook

This repository is designed to guide developers from Elixir fundamentals through advanced concurrent programming and production-ready applications. Each chapter includes structured learning materials with practical exercises that build upon previous concepts, culminating in a complete distributed Todo application.

> **⚠️ Copyright Notice:** PDF files from "Elixir in Action" have been omitted from this repository to respect copyright law. You must obtain your own legal copy of the book from [Manning Publications](https://www.manning.com/books/elixir-in-action-third-edition) or other authorized retailers. This repository contains only original learning materials, exercises, and organizational tools.

## Repository Structure

```
.
├── data/
│   ├── Elixir_in_Action_Third_Edition.json    # Book structure metadata
│   └── WORKBOOK/                              # Chapter-by-chapter learning materials
│       ├── chapter_1.md                       # Building blocks
│       ├── chapter_2.md                       # Data structures
│       ├── ...
│       └── chapter_13.md                      # Running the system
├── .devcontainer/                             # Docker development environment
├── do.ipynb                                   # PDF extraction utility (for personal use)
├── LICENSE                                    # MIT License
└── README.md                                  # This file
```

**Note:** PDF files and extracted chapters are not included in this repository. If you legally own the book, you can use the `do.ipynb` notebook to extract chapters for your personal study.

## Learning Path

### Part 1: Functional Elixir (Chapters 1-4)
- **Chapter 1:** Building blocks - Elixir fundamentals and BEAM VM
- **Chapter 2:** Data structures - Working with Elixir's immutable data types
- **Chapter 3:** Control flow - Pattern matching, conditionals, and iteration
- **Chapter 4:** Data abstractions - Protocols and behaviours

### Part 2: Concurrent Elixir (Chapters 5-10)
- **Chapter 5:** Concurrency primitives - Processes and message passing
- **Chapter 6:** Generic server processes - Building stateful servers
- **Chapter 7:** Building a concurrent system - Process supervision
- **Chapter 8:** Fault-tolerance basics - Let it crash philosophy
- **Chapter 9:** Isolating error effects - Supervision trees
- **Chapter 10:** Beyond GenServer - Agents, Tasks, and ETS

### Part 3: Production (Chapters 11-13)
- **Chapter 11:** Working with components - Mix, OTP applications
- **Chapter 12:** Building a web server - Plug and Cowboy
- **Chapter 13:** Running the system - Deployment and operations

## Getting Started

### Prerequisites

- **A legal copy of "Elixir in Action, 3rd Edition"** - [Purchase from Manning](https://www.manning.com/books/elixir-in-action-third-edition) or authorized retailers
- **Elixir** 1.14+ and **Erlang/OTP** 25+ installed ([Installation Guide](https://elixir-lang.org/install.html))
- Basic programming knowledge (any language)
- Text editor or IDE (VS Code recommended with ElixirLS extension)

### Quick Start

1. **Clone the repository:**
   ```bash
   git clone <your-repository-url>
   cd Elixir_In_Action_Workbook
   ```

2. **Start with Chapter 1:**
   ```bash
   # Open the first workbook chapter
   cat WORKBOOK/chapter_1.md
   ```

3. **Work through each chapter systematically:**
   - Read the corresponding chapter in your book
   - Review the workbook summary and exercises
   - Complete the concept drills
   - Build the chapter project
   - Check your work with the self-correction checklist

### Using the Development Container

For a consistent development environment with all dependencies pre-configured:

1. **Install Prerequisites:**
   - [Docker Desktop](https://www.docker.com/products/docker-desktop)
   - [VS Code](https://code.visualstudio.com/) with [Remote-Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

2. **Open in Container:**
   ```bash
   # VS Code will prompt to reopen in container
   code .
   ```

The container includes:
- **Elixir 1.19.4** with OTP 27 and Phoenix framework
- **Python 3** with Jupyter, pandas, and PDF processing libraries (PyMuPDF, PyPDF2)
- **Node.js 20 LTS** for Phoenix LiveView and asset management
- **PostgreSQL client** for database access
- **VS Code extensions** for Elixir, Python, and Jupyter development

## How to Use This Workbook

### Learning Methodology

Each chapter workbook (`WORKBOOK/chapter_X.md`) follows a structured approach:

1. **Chapter Summary:** High-level overview of key concepts
2. **Concept Drills:** Focused exercises to reinforce understanding
3. **Projects:** Practical applications building toward a complete system
4. **Self-Correction:** Checklists to verify your understanding

### Recommended Workflow

```bash
# 1. Read the chapter in your book

# 2. Review the workbook summary
cat WORKBOOK/chapter_Y.md

# 3. Complete drills in an Elixir project
mix new chapter_Y_drills
cd chapter_Y_drills
iex -S mix

# 4. Build the chapter project
mix new chapter_Y_project --sup
cd chapter_Y_project

# 5. Run tests and verify
mix test
```

### Progressive Projects

The workbook guides you through building increasingly sophisticated components:
- **Early Chapters:** Simple modules and functions
- **Mid Chapters:** Concurrent servers and supervision trees
- **Later Chapters:** Complete OTP applications with web interfaces
- **Final Chapters:** Distributed systems and production deployment

## Utilities

### PDF Extraction Notebook (Personal Use Only)

The `do.ipynb` Jupyter notebook contains utilities for extracting chapters from your personal copy of the book PDF:

```python
# Extract individual chapters from the full PDF
# Uses PyMuPDF and the JSON metadata to create chapter-specific PDFs
```

**Important:** This tool is provided for personal study convenience only. You must:
- Own a legal copy of "Elixir in Action, 3rd Edition"
- Use extracted PDFs solely for your own learning
- Never distribute or share extracted PDF files

To use (after obtaining your own copy of the book):
```bash
# Place your legally obtained PDF in the data/ directory
jupyter notebook do.ipynb
```

## Project Structure Details

### Metadata Format

`data/Elixir_in_Action_Third_Edition.json` provides the book's structure:

```json
{
  "title": "Elixir in Action, Third Edition",
  "author": "Saša Jurić",
  "total_pages": 413,
  "chapters": [
    {
      "number": 1,
      "title": "First steps",
      "start_page": 25,
      "end_page": 51
    }
    // ... more chapters
  ]
}
```

### Workbook Format

Each chapter markdown file includes:
- **Learning objectives**
- **Concept explanations** with code examples
- **Hands-on drills** for practice
- **Project specifications** for building real applications
- **Self-assessment questions**

## Development Tools Included

The `.devcontainer` setup provides a complete development environment with:

**Elixir Stack:**
- Elixir 1.19.4 with OTP 27
- Mix build tool and Hex package manager
- Phoenix 1.8.3 framework
- PostgreSQL 16 database

**Python Stack:**
- Python 3 with pip and venv
- Jupyter Notebook for interactive development
- PDF processing (PyMuPDF, PyPDF2)
- Data analysis (pandas)

**VS Code Extensions:**
- ElixirLS for Elixir development
- Phoenix framework support
- Python extension with Pylance
- Jupyter notebooks
- TailwindCSS IntelliSense
- GitHub Copilot

## Contributing

Contributions are welcome! If you find errors, have suggestions for improvements, or want to add additional exercises:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/improvement`)
3. Commit your changes (`git commit -am 'Add new drill for Chapter 5'`)
4. Push to the branch (`git push origin feature/improvement`)
5. Open a Pull Request

### Areas for Contribution

- Additional practice exercises
- Solution examples (with spoiler warnings)
- Testing strategies and examples
- Real-world project extensions
- Bug fixes and clarifications

## Resources

- [Official Elixir Documentation](https://elixir-lang.org/docs.html)
- [Elixir School](https://elixirschool.com/en)
- [Elixir Forum](https://elixirforum.com/)
- [Exercism Elixir Track](https://exercism.org/tracks/elixir)
- [Elixir in Action Book](https://www.manning.com/books/elixir-in-action-third-edition)

## Learning Tips

1. **Type everything yourself** - Don't copy-paste code examples
2. **Experiment actively** - Modify examples to see what happens
3. **Use IEx extensively** - The interactive shell is your friend
4. **Read error messages carefully** - Elixir's errors are informative
5. **Build progressively** - Each chapter builds on previous concepts
6. **Test your code** - Write tests as you learn
7. **Join the community** - Ask questions on forums and Slack

## License and Copyright

This workbook's original content (exercises, drills, project specifications, and organizational materials) is released under the MIT License. See [LICENSE](LICENSE) for details.

**Copyright Compliance:**
- "Elixir in Action, 3rd Edition" is copyrighted © 2024 by Manning Publications
- The book content is NOT included in this repository to respect copyright law
- PDF files and book text are explicitly excluded from this repository's version control (see `.gitignore`)
- You must obtain your own legal copy of the book from [Manning Publications](https://www.manning.com/books/elixir-in-action-third-edition) or authorized retailers
- This repository provides only supplementary learning materials and should be used alongside the official book

**Please support the author Saša Jurić and Manning Publications by purchasing the book legally.**

## Acknowledgments

- **Saša Jurić** - Author of "Elixir in Action"
- **Manning Publications** - Publisher
- The **Elixir Core Team** - For creating an amazing language
- The **Elixir Community** - For extensive documentation and support

---

**Happy Learning!**

Start your Elixir journey today with Chapter 1: Building Blocks
