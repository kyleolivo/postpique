# PostPique

A macOS app that enables quick sharing of quotes and thoughts from web articles directly to your GitHub Pages blog.

## Features

- **GitHub Authentication**: Secure OAuth device flow authentication
- **Repository Selection**: Choose which GitHub repository to save posts to
- **Share Extension**: Use the system share menu to quickly capture content
- **Markdown Generation**: Automatically formats posts for Jekyll/GitHub Pages

## How It Works

1. **Setup**: Sign in with GitHub and select a repository
2. **Share**: When reading an article, use the share menu
3. **Add Context**: Enter a quote from the article and your thoughts
4. **Publish**: Posts are saved as markdown files in your repository's `_posts` folder

## Technical Details

- Built with SwiftUI for macOS
- Uses GitHub API for repository access
- Stores credentials securely in UserDefaults with app groups
- Generates Jekyll-compatible markdown with proper front matter

## Post Format

Posts are saved as markdown files with:
- Automatic date-based filenames
- Jekyll front matter with title and tags
- Quoted text in blockquote format
- Your commentary below the quote
- Link back to the original article

Example:
```markdown
---
title: "🔗 Article Title"
excerpt_separator: "<!--more-->"
tags:
  - quotes
---
> This is the quote from the article

This is your commentary about the quote.

[Full article](https://example.com/article)
```