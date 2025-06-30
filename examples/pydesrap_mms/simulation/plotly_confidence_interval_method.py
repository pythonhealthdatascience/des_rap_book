"""
plotly_confidence_interval_method.

Acknowledgements
----------------
This code is adapted from Tom Monks (2021) sim-tools: fundamental tools to
support the simulation process in python
(https://github.com/TomMonks/sim-tools) (MIT Licence).
"""

import plotly.graph_objects as go


def plotly_confidence_interval_method(
    conf_ints, metric_name, n_reps=None, figsize=(1200, 400), file_path=None
):
    """
    Generates an interactive Plotly visualisation of confidence intervals
    with increasing simulation replications.

    Parameters
    ----------
    conf_ints : pd.DataFrame
        A DataFrame containing confidence interval statistics, including
        cumulative mean, upper/lower bounds, and deviations. As returned
        by ReplicationTabulizer summary_table() method.
    metric_name : str
        Name of metric being analysed.
    n_reps : int, optional
        The number of replications required to meet the desired precision.
    figsize : tuple, optional
        Plot dimensions in pixels (width, height).
    file_path : str, optional
        Path and filename to save the plot to.

    Returns
    -------
    plotly.graph_objects.Figure
        The generated Plotly figure.

    Notes
    -----
    Function adapted from Monks 2021.
    """
    fig = go.Figure()

    # Calculate relative deviations
    deviation_pct = (
        (conf_ints["upper_ci"] - conf_ints["cumulative_mean"])
        / conf_ints["cumulative_mean"]
        * 100
    ).round(2)

    # Confidence interval as shaded region
    fig.add_trace(
        go.Scatter(
            x=conf_ints["replications"],
            y=conf_ints["upper_ci"],
            mode="lines",
            line={"width": 0},
            showlegend=False,
            name="Upper CI",
            text=[f"Deviation: {d}%" for d in deviation_pct]
        )
    )
    fig.add_trace(
        go.Scatter(
            x=conf_ints["replications"],
            y=conf_ints["lower_ci"],
            mode="lines",
            line={"width": 0},
            fill="tonexty",  # Fill to previous y trace
            fillcolor="rgba(0, 176, 185, 0.2)",  # Semi-transparent fill
            name="Confidence interval"
        )
    )

    # Cumulative mean line with enhanced hover
    fig.add_trace(
        go.Scatter(
            x=conf_ints["replications"],
            y=conf_ints["cumulative_mean"],
            line={"color": "blue", "width": 2},
            name="Cumulative Mean",
            hoverinfo="x+y+name"
        )
    )

    # Vertical threshold line
    if n_reps is not None:
        fig.add_shape(
            type="line",
            x0=n_reps,
            x1=n_reps,
            y0=0,
            y1=1,
            yref="paper",
            line={"color": "red", "dash": "dash"}
        )

    # Configure layout
    fig.update_layout(
        width=figsize[0],
        height=figsize[1],
        yaxis_title=f"Cumulative Mean:\n{metric_name}",
        hovermode="x unified",
        showlegend=True,
    )

    # Save figure
    if file_path is not None:
        fig.write_image(file_path)
    return fig
