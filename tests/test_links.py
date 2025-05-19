import os
import re
import pytest


def extract_links_from_file(filepath):
    """
    Extract markdown links from a file.

    Parameters
    ----------
    filepath : str
        Path to the file from which to extract markdown links.

    Returns
    -------
    list of str
        A list of link targets (the URLs or paths inside the parentheses of
        markdown links).
    """
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()
    # Regex to extract markdown links: [text](path)
    return re.findall(r"\[.*?\]\((.*?)\)", content)


@pytest.mark.parametrize("root_dir", ["."], ids=["project_root"])
def test_quarto_links(root_dir):
    """
    Test that all internal markdown links in .qmd and .md files are valid.

    Parameters
    ----------
    root_dir : str
        The root directory to search for markdown and quarto files.

    Raises
    ------
    AssertionError
        If any internal link points to a non-existent file, an AssertionError
        is raised with a report of all broken links found.
    """
    broken_links = []
    # Walk through all files in the project directory
    for dirpath, _, filenames in os.walk(root_dir):
        for filename in filenames:
            if filename.endswith(".qmd") or filename.endswith(".md"):
                file_path = os.path.join(dirpath, filename)
                links = extract_links_from_file(file_path)
                for link in links:
                    # Ignore external links
                    if "://" in link or link.startswith("#"):
                        continue
                    # Normalise relative to the file's directory
                    link_path = os.path.normpath(os.path.join(dirpath, link))
                    if not os.path.exists(link_path):
                        broken_links.append(f"In {file_path}: link to " +
                                            "'{link}' does not exist.")
    assert not broken_links, "Broken links found:\n" + "\n".join(broken_links)
