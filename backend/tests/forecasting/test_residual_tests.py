"""Tests for residual statistical test utilities."""
import numpy as np
import pytest

from app.forecasting.residual_tests import (
    breusch_pagan,
    ljung_box,
    run_all_tests,
    shapiro_wilk,
)


@pytest.fixture
def rng():
    return np.random.default_rng(seed=42)


# =========================
# Ljung-Box
# =========================

def test_ljung_box_passes_on_white_noise(rng):
    residuals = rng.standard_normal(500)
    result = ljung_box(residuals)
    assert result.test_name == "Ljung-Box"
    assert result.p_value > 0.05
    assert result.passes is True


def test_ljung_box_fails_on_ar1(rng):
    # Strong AR(1) process — residuals of the "null" model should show autocorrelation
    n = 500
    phi = 0.8
    ar = np.zeros(n)
    noise = rng.standard_normal(n)
    for i in range(1, n):
        ar[i] = phi * ar[i - 1] + noise[i]
    result = ljung_box(ar)
    assert result.p_value < 0.01
    assert result.passes is False


def test_ljung_box_skips_when_too_few():
    result = ljung_box(np.array([0.1, -0.2, 0.1]))
    assert "Skipped" in result.interpretation
    assert result.passes is False


# =========================
# Breusch-Pagan
# =========================

def test_breusch_pagan_passes_on_homoscedastic(rng):
    # Constant-variance residuals vs a linear fitted index.
    # Average over 5 runs to smooth out Type I error flukes.
    n = 500
    fitted = np.linspace(0, 100, n)
    passes_count = 0
    for seed in range(5):
        sub_rng = np.random.default_rng(seed=seed)
        residuals = sub_rng.standard_normal(n)
        result = breusch_pagan(residuals, fitted)
        if result.passes:
            passes_count += 1
    # At 5% Type I error, expect ~4.75/5 to pass; require at least 3
    assert passes_count >= 3


def test_breusch_pagan_fails_on_heteroscedastic(rng):
    # Variance grows with fitted — classic heteroscedasticity
    n = 300
    fitted = np.linspace(1, 50, n)
    residuals = rng.standard_normal(n) * fitted
    result = breusch_pagan(residuals, fitted)
    assert result.p_value < 0.01
    assert result.passes is False


def test_breusch_pagan_skips_when_too_few():
    result = breusch_pagan(np.array([0.1, -0.2, 0.1]))
    assert "Skipped" in result.interpretation


# =========================
# Shapiro-Wilk
# =========================

def test_shapiro_passes_on_gaussian(rng):
    residuals = rng.standard_normal(200)
    result = shapiro_wilk(residuals)
    assert result.test_name == "Shapiro-Wilk"
    assert result.p_value > 0.05
    assert result.passes is True


def test_shapiro_fails_on_exponential(rng):
    residuals = rng.exponential(1.0, 200)
    result = shapiro_wilk(residuals)
    assert result.p_value < 0.01
    assert result.passes is False


def test_shapiro_skips_above_5000(rng):
    residuals = rng.standard_normal(6000)
    result = shapiro_wilk(residuals)
    assert "5000" in result.interpretation
    assert result.passes is False


def test_shapiro_skips_below_3():
    result = shapiro_wilk(np.array([0.1, -0.2]))
    assert "Skipped" in result.interpretation


# =========================
# run_all_tests
# =========================

def test_run_all_returns_three_results(rng):
    residuals = rng.standard_normal(300)
    fitted = np.linspace(0, 100, 300)
    tests = run_all_tests(residuals, fitted)
    names = [t.test_name for t in tests]
    assert names == ["Ljung-Box", "Breusch-Pagan", "Shapiro-Wilk"]
