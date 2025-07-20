# Step 3. Filtering low-reliable variants based on beta-binomial error model

import numpy as np
import pandas as pd
import argparse
import scipy.stats as stats
from statsmodels.stats.multitest import multipletests


# Beta-binomial model
def beta_binomial_pval(total_depth, alt_depth, alpha, beta):
    """Calculate p-value using Beta-Binomial model."""
    return 1 - stats.betabinom.cdf(alt_depth - 1, total_depth, alpha, beta)


# Parameter estimation and variant filtering
def estimate_and_filter(input_file: str, output_file: str, err_threshold: float = 1.0, fdr_threshold: float = 0.05):
    df = pd.read_csv(input_file, sep="\t")
    df["total_depth"] = df["delread"] + df["wtread"]
    print(f"All rows: {len(df)}")
    
    # Base error model estimation
    be_df = df[df["heteroplasmy"] < err_threshold]
    print(f"Base error rows (heteroplasmy < {err_threshold}%): {len(be_df)}")
    error_rates = be_df["delread"] / be_df["total_depth"]
    mean_error = np.mean(error_rates)
    var_error = np.var(error_rates)
    alpha = mean_error * ((mean_error * (1 - mean_error) / var_error) - 1)
    beta = (1 - mean_error) * ((mean_error * (1 - mean_error) / var_error) - 1)
    print(f"Estimated beta distribution parameter: alpha={alpha:.3f}, beta={beta:.3f}")

    # Calculate p-values
    df["p_value"] = df.apply(lambda row: beta_binomial_pval(row["total_depth"], row["delread"], alpha, beta), axis=1)

    # Filter out deletions with delread=1 or wtread=0
    df = df[(df["wtread"] != 0) & (df["delread"] != 1)]
    print(f"Filtered rows (delread ≠ 1 and wtread ≠ 0): {len(df)}")

    # FDR correction
    df["q_value"] = multipletests(df["p_value"], method="fdr_bh")[1]

    # Output significant rows
    sig_df = df[df["q_value"] < fdr_threshold]
    print(f"Significant variants (q < {fdr_threshold}): {len(sig_df)}")
    
    # Save output
    sig_df.to_csv(output_file, sep="\t", index=False)
    print(f"Filtered data saved to {output_file}")



# Main
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='filtering')
    parser.add_argument('input_file', type=str, help='input file')
    parser.add_argument('output_file', type=str, help='output file')
    parser.add_argument('--err', type=float, default=1.0, help='error assumed threshold')
    parser.add_argument('--fdr', type=float, default=0.05, help='FDR threshold')
    args = parser.parse_args()
    
    estimate_and_filter(args.input_file, args.output_file, args.err, args.fdr)
