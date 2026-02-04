"""
Unit tests for roster service functions.

Tests the calculate_event_dates() function and _get_monthly_date() helper
for correct handling of recurrence patterns, especially monthly patterns
with edge cases like day 31 in shorter months and leap years.
"""

from datetime import date

import pytest

from app.models.roster import RecurrencePattern
from app.services.roster import _get_monthly_date, calculate_event_dates


class TestGetMonthlyDate:
    """Tests for the _get_monthly_date() helper function."""

    def test_normal_day(self):
        """Day 15 in any month returns expected date without clamping."""
        result = _get_monthly_date(2024, 3, 15)
        assert result == date(2024, 3, 15)

    def test_day_31_in_31_day_month(self):
        """Day 31 in a 31-day month (January) returns day 31."""
        result = _get_monthly_date(2024, 1, 31)
        assert result == date(2024, 1, 31)

    def test_day_31_in_30_day_month(self):
        """Day 31 in April (30 days) falls back to day 30."""
        result = _get_monthly_date(2024, 4, 31)
        assert result == date(2024, 4, 30)

    def test_day_31_in_june(self):
        """Day 31 in June (30 days) falls back to day 30."""
        result = _get_monthly_date(2024, 6, 31)
        assert result == date(2024, 6, 30)

    def test_day_31_in_september(self):
        """Day 31 in September (30 days) falls back to day 30."""
        result = _get_monthly_date(2024, 9, 31)
        assert result == date(2024, 9, 30)

    def test_day_31_in_november(self):
        """Day 31 in November (30 days) falls back to day 30."""
        result = _get_monthly_date(2024, 11, 31)
        assert result == date(2024, 11, 30)

    def test_day_31_in_february_leap_year(self):
        """Day 31 in February of a leap year (2024) falls back to day 29."""
        result = _get_monthly_date(2024, 2, 31)
        assert result == date(2024, 2, 29)

    def test_day_31_in_february_non_leap_year(self):
        """Day 31 in February of a non-leap year (2023) falls back to day 28."""
        result = _get_monthly_date(2023, 2, 31)
        assert result == date(2023, 2, 28)

    def test_day_30_in_february_leap_year(self):
        """Day 30 in February of a leap year (2024) falls back to day 29."""
        result = _get_monthly_date(2024, 2, 30)
        assert result == date(2024, 2, 29)

    def test_day_30_in_february_non_leap_year(self):
        """Day 30 in February of a non-leap year (2023) falls back to day 28."""
        result = _get_monthly_date(2023, 2, 30)
        assert result == date(2023, 2, 28)

    def test_day_29_in_february_leap_year(self):
        """Day 29 in February of a leap year (2024) returns day 29."""
        result = _get_monthly_date(2024, 2, 29)
        assert result == date(2024, 2, 29)

    def test_day_29_in_february_non_leap_year(self):
        """Day 29 in February of a non-leap year (2023) falls back to day 28."""
        result = _get_monthly_date(2023, 2, 29)
        assert result == date(2023, 2, 28)

    def test_day_1_in_any_month(self):
        """Day 1 is always valid in any month."""
        result = _get_monthly_date(2024, 2, 1)
        assert result == date(2024, 2, 1)


class TestCalculateEventDatesMonthly:
    """Tests for calculate_event_dates() with monthly recurrence."""

    def test_monthly_day_31_full_year(self):
        """Monthly recurrence on day 31 generates correct dates across all months."""
        dates = calculate_event_dates(
            start_date=date(2024, 1, 1),
            recurrence_pattern=RecurrencePattern.MONTHLY,
            recurrence_day=31,
            count=12,
        )

        assert len(dates) == 12
        # January 31 (31 days)
        assert dates[0] == date(2024, 1, 31)
        # February 29 (leap year, day 31 clamped to 29)
        assert dates[1] == date(2024, 2, 29)
        # March 31 (31 days)
        assert dates[2] == date(2024, 3, 31)
        # April 30 (30 days, day 31 clamped to 30)
        assert dates[3] == date(2024, 4, 30)
        # May 31 (31 days)
        assert dates[4] == date(2024, 5, 31)
        # June 30 (30 days)
        assert dates[5] == date(2024, 6, 30)
        # July 31 (31 days)
        assert dates[6] == date(2024, 7, 31)
        # August 31 (31 days)
        assert dates[7] == date(2024, 8, 31)
        # September 30 (30 days)
        assert dates[8] == date(2024, 9, 30)
        # October 31 (31 days)
        assert dates[9] == date(2024, 10, 31)
        # November 30 (30 days)
        assert dates[10] == date(2024, 11, 30)
        # December 31 (31 days)
        assert dates[11] == date(2024, 12, 31)

    def test_monthly_day_31_non_leap_year(self):
        """Monthly recurrence on day 31 in non-leap year handles Feb correctly."""
        dates = calculate_event_dates(
            start_date=date(2023, 1, 1),
            recurrence_pattern=RecurrencePattern.MONTHLY,
            recurrence_day=31,
            count=3,
        )

        assert len(dates) == 3
        assert dates[0] == date(2023, 1, 31)
        # February 28 (non-leap year)
        assert dates[1] == date(2023, 2, 28)
        assert dates[2] == date(2023, 3, 31)

    def test_monthly_year_boundary(self):
        """Monthly recurrence correctly crosses December to January."""
        dates = calculate_event_dates(
            start_date=date(2024, 11, 1),
            recurrence_pattern=RecurrencePattern.MONTHLY,
            recurrence_day=15,
            count=4,
        )

        assert len(dates) == 4
        assert dates[0] == date(2024, 11, 15)
        assert dates[1] == date(2024, 12, 15)
        assert dates[2] == date(2025, 1, 15)
        assert dates[3] == date(2025, 2, 15)

    def test_monthly_year_boundary_with_day_31(self):
        """Monthly day 31 recurrence correctly crosses December to January."""
        dates = calculate_event_dates(
            start_date=date(2024, 10, 1),
            recurrence_pattern=RecurrencePattern.MONTHLY,
            recurrence_day=31,
            count=5,
        )

        assert len(dates) == 5
        assert dates[0] == date(2024, 10, 31)
        assert dates[1] == date(2024, 11, 30)
        assert dates[2] == date(2024, 12, 31)
        assert dates[3] == date(2025, 1, 31)
        # February 2025 is not a leap year
        assert dates[4] == date(2025, 2, 28)

    def test_monthly_with_end_date(self):
        """Monthly recurrence respects end_date boundary."""
        dates = calculate_event_dates(
            start_date=date(2024, 1, 1),
            recurrence_pattern=RecurrencePattern.MONTHLY,
            recurrence_day=15,
            count=12,
            end_date=date(2024, 3, 20),
        )

        assert len(dates) == 3
        assert dates[0] == date(2024, 1, 15)
        assert dates[1] == date(2024, 2, 15)
        assert dates[2] == date(2024, 3, 15)

    def test_monthly_with_end_date_exact(self):
        """Monthly recurrence includes event on end_date."""
        dates = calculate_event_dates(
            start_date=date(2024, 1, 1),
            recurrence_pattern=RecurrencePattern.MONTHLY,
            recurrence_day=15,
            count=12,
            end_date=date(2024, 2, 15),
        )

        assert len(dates) == 2
        assert dates[0] == date(2024, 1, 15)
        assert dates[1] == date(2024, 2, 15)

    def test_monthly_with_end_after_occurrences(self):
        """Monthly recurrence respects occurrence limit."""
        dates = calculate_event_dates(
            start_date=date(2024, 1, 1),
            recurrence_pattern=RecurrencePattern.MONTHLY,
            recurrence_day=15,
            count=12,
            end_after_occurrences=3,
        )

        assert len(dates) == 3
        assert dates[0] == date(2024, 1, 15)
        assert dates[1] == date(2024, 2, 15)
        assert dates[2] == date(2024, 3, 15)

    def test_monthly_start_after_recurrence_day(self):
        """Start date after recurrence day moves to next month."""
        dates = calculate_event_dates(
            start_date=date(2024, 1, 20),
            recurrence_pattern=RecurrencePattern.MONTHLY,
            recurrence_day=15,
            count=3,
        )

        assert len(dates) == 3
        # First occurrence in February since Jan 20 > Jan 15
        assert dates[0] == date(2024, 2, 15)
        assert dates[1] == date(2024, 3, 15)
        assert dates[2] == date(2024, 4, 15)

    def test_monthly_start_before_recurrence_day(self):
        """Start date before recurrence day uses same month."""
        dates = calculate_event_dates(
            start_date=date(2024, 1, 10),
            recurrence_pattern=RecurrencePattern.MONTHLY,
            recurrence_day=15,
            count=3,
        )

        assert len(dates) == 3
        assert dates[0] == date(2024, 1, 15)
        assert dates[1] == date(2024, 2, 15)
        assert dates[2] == date(2024, 3, 15)

    def test_monthly_start_on_recurrence_day(self):
        """Start date on recurrence day uses that day."""
        dates = calculate_event_dates(
            start_date=date(2024, 1, 15),
            recurrence_pattern=RecurrencePattern.MONTHLY,
            recurrence_day=15,
            count=3,
        )

        assert len(dates) == 3
        assert dates[0] == date(2024, 1, 15)
        assert dates[1] == date(2024, 2, 15)
        assert dates[2] == date(2024, 3, 15)

    def test_monthly_day_30_february(self):
        """Monthly recurrence on day 30 handles February correctly."""
        dates = calculate_event_dates(
            start_date=date(2024, 1, 1),
            recurrence_pattern=RecurrencePattern.MONTHLY,
            recurrence_day=30,
            count=3,
        )

        assert len(dates) == 3
        assert dates[0] == date(2024, 1, 30)
        # Feb 29 in leap year (clamped from 30)
        assert dates[1] == date(2024, 2, 29)
        assert dates[2] == date(2024, 3, 30)

    def test_monthly_day_29_february_non_leap(self):
        """Monthly recurrence on day 29 handles non-leap February correctly."""
        dates = calculate_event_dates(
            start_date=date(2023, 1, 1),
            recurrence_pattern=RecurrencePattern.MONTHLY,
            recurrence_day=29,
            count=3,
        )

        assert len(dates) == 3
        assert dates[0] == date(2023, 1, 29)
        # Feb 28 in non-leap year (clamped from 29)
        assert dates[1] == date(2023, 2, 28)
        assert dates[2] == date(2023, 3, 29)


class TestCalculateEventDatesWeekly:
    """Tests for calculate_event_dates() with weekly recurrence (unchanged behavior)."""

    def test_weekly_unchanged(self):
        """Weekly pattern still works correctly."""
        dates = calculate_event_dates(
            start_date=date(2024, 1, 1),  # Monday
            recurrence_pattern=RecurrencePattern.WEEKLY,
            recurrence_day=0,  # Monday
            count=4,
        )

        assert len(dates) == 4
        assert dates[0] == date(2024, 1, 1)  # Mon
        assert dates[1] == date(2024, 1, 8)  # Mon
        assert dates[2] == date(2024, 1, 15)  # Mon
        assert dates[3] == date(2024, 1, 22)  # Mon

    def test_weekly_different_day(self):
        """Weekly pattern on Friday (weekday 4)."""
        dates = calculate_event_dates(
            start_date=date(2024, 1, 1),  # Monday
            recurrence_pattern=RecurrencePattern.WEEKLY,
            recurrence_day=4,  # Friday
            count=3,
        )

        assert len(dates) == 3
        assert dates[0] == date(2024, 1, 5)  # Fri
        assert dates[1] == date(2024, 1, 12)  # Fri
        assert dates[2] == date(2024, 1, 19)  # Fri

    def test_weekly_sunday(self):
        """Weekly pattern on Sunday (weekday 6)."""
        dates = calculate_event_dates(
            start_date=date(2024, 1, 1),  # Monday
            recurrence_pattern=RecurrencePattern.WEEKLY,
            recurrence_day=6,  # Sunday
            count=3,
        )

        assert len(dates) == 3
        assert dates[0] == date(2024, 1, 7)  # Sun
        assert dates[1] == date(2024, 1, 14)  # Sun
        assert dates[2] == date(2024, 1, 21)  # Sun

    def test_weekly_with_end_date(self):
        """Weekly recurrence respects end_date."""
        dates = calculate_event_dates(
            start_date=date(2024, 1, 1),  # Monday
            recurrence_pattern=RecurrencePattern.WEEKLY,
            recurrence_day=0,  # Monday
            count=12,
            end_date=date(2024, 1, 20),
        )

        assert len(dates) == 3
        assert dates[0] == date(2024, 1, 1)
        assert dates[1] == date(2024, 1, 8)
        assert dates[2] == date(2024, 1, 15)


class TestCalculateEventDatesBiweekly:
    """Tests for calculate_event_dates() with biweekly recurrence (unchanged behavior)."""

    def test_biweekly_unchanged(self):
        """Biweekly pattern still works correctly."""
        dates = calculate_event_dates(
            start_date=date(2024, 1, 1),  # Monday
            recurrence_pattern=RecurrencePattern.BIWEEKLY,
            recurrence_day=0,  # Monday
            count=4,
        )

        assert len(dates) == 4
        assert dates[0] == date(2024, 1, 1)  # Mon
        assert dates[1] == date(2024, 1, 15)  # Mon (2 weeks later)
        assert dates[2] == date(2024, 1, 29)  # Mon (2 weeks later)
        assert dates[3] == date(2024, 2, 12)  # Mon (2 weeks later)

    def test_biweekly_different_day(self):
        """Biweekly pattern on Wednesday (weekday 2)."""
        dates = calculate_event_dates(
            start_date=date(2024, 1, 1),  # Monday
            recurrence_pattern=RecurrencePattern.BIWEEKLY,
            recurrence_day=2,  # Wednesday
            count=3,
        )

        assert len(dates) == 3
        assert dates[0] == date(2024, 1, 3)  # Wed
        assert dates[1] == date(2024, 1, 17)  # Wed (2 weeks later)
        assert dates[2] == date(2024, 1, 31)  # Wed (2 weeks later)

    def test_biweekly_with_end_after_occurrences(self):
        """Biweekly recurrence respects occurrence limit."""
        dates = calculate_event_dates(
            start_date=date(2024, 1, 1),
            recurrence_pattern=RecurrencePattern.BIWEEKLY,
            recurrence_day=0,
            count=10,
            end_after_occurrences=2,
        )

        assert len(dates) == 2
        assert dates[0] == date(2024, 1, 1)
        assert dates[1] == date(2024, 1, 15)


class TestCalculateEventDatesOneTime:
    """Tests for calculate_event_dates() with one-time events."""

    def test_one_time(self):
        """One-time pattern returns only the start date."""
        dates = calculate_event_dates(
            start_date=date(2024, 3, 15),
            recurrence_pattern=RecurrencePattern.ONE_TIME,
            recurrence_day=0,  # Ignored for one-time
            count=10,
        )

        assert len(dates) == 1
        assert dates[0] == date(2024, 3, 15)
