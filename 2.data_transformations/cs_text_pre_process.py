"""Module containing function to preprocess text in a Pandas DataFrame column using regex patterns."""

import pandas as pd


def pattern_preprocessing_cs(input_column: pd.Series[str], pattern: str) -> pd.Series[str]:
    """
    Preprocesses text in a Pandas DataFrame column using regex patterns.

    Args:
        input_column (pd.Series[str]): Pandas series of strings to be preprocessed.
        pattern (str): Regex pattern to be used for preprocessing.

    Returns:
        pd.Series[str]: Processed Pandas series.
    """
    return input_column.str.replace(pattern, " ", regex=True) \
        .str.replace(r"\.{2,}", ".", regex=True) \
        .str.strip() \
        .str.replace(r"  +", " ", regex=True)
