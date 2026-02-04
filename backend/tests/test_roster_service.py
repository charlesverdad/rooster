"""Tests for roster service event date calculation logic."""

from datetime import date

from app.models.roster import RecurrencePattern
from app.services.roster import _get_monthly_date, calculate_event_dates


class TestGetMonthlyDate:
    def test_normal_day(self):
        assert _get_monthly_date(2025, 3, 15) == date(2025, 3, 15)

    def test_clamp_day_31_to_february(self):
        assert _get_monthly_date(2025, 2, 31) == date(2025, 2, 28)

    def test_clamp_day_31_to_february_leap_year(self):
        assert _get_monthly_date(2024, 2, 31) == date(2024, 2, 29)

    def test_clamp_day_30_to_february(self):
        assert _get_monthly_date(2025, 2, 30) == date(2025, 2, 28)

    def test_clamp_day_31_to_april(self):
        assert _get_monthly_date(2025, 4, 31) == date(2025, 4, 30)

    def test_clamp_day_31_to_june(self):
        assert _get_monthly_date(2025, 6, 31) == date(2025, 6, 30)

    def test_day_31_in_january(self):
        assert _get_monthly_date(2025, 1, 31) == date(2025, 1, 31)

    def test_day_31_in_december(self):
        assert _get_monthly_date(2025, 12, 31) == date(2025, 12, 31)


class TestCalculateEventDatesOneTime:
    def test_one_time_returns_single_date(self):
        dates = calculate_event_dates(
            start_date=date(2025, 6, 15),
            recurrence_pattern=RecurrencePattern.ONE_TIME,
            recurrence_day=0,
            count=10,
        )
        assert dates == [date(2025, 6, 15)]

    def test_one_time_ignores_count(self):
        dates = calculate_event_dates(
            start_date=date(2025, 1, 1),
            recurrence_pattern=RecurrencePattern.ONE_TIME,
            recurrence_day=0,
            count=100,
        )
        assert len(dates) == 1


class TestCalculateEventDatesWeekly:
    def test_weekly_generates_correct_count(self):
        # Monday (0) starting on a Monday
        dates = calculate_event_dates(
            start_date=date(2025, 6, 2),  # Monday
            recurrence_pattern=RecurrencePattern.WEEKLY,
            recurrence_day=0,  # Monday
            count=4,
        )
        assert len(dates) == 4
        assert dates[0] == date(2025, 6, 2)
        assert dates[1] == date(2025, 6, 9)
        assert dates[2] == date(2025, 6, 16)
        assert dates[3] == date(2025, 6, 23)

    def test_weekly_respects_end_date(self):
        dates = calculate_event_dates(
            start_date=date(2025, 6, 2),
            recurrence_pattern=RecurrencePattern.WEEKLY,
            recurrence_day=0,
            count=100,
            end_date=date(2025, 6, 20),
        )
        assert all(d <= date(2025, 6, 20) for d in dates)
        assert len(dates) == 3

    def test_weekly_respects_end_after_occurrences(self):
        dates = calculate_event_dates(
            start_date=date(2025, 6, 2),
            recurrence_pattern=RecurrencePattern.WEEKLY,
            recurrence_day=0,
            count=100,
            end_after_occurrences=5,
        )
        assert len(dates) == 5


class TestCalculateEventDatesBiweekly:
    def test_biweekly_two_week_gap(self):
        dates = calculate_event_dates(
            start_date=date(2025, 6, 2),
            recurrence_pattern=RecurrencePattern.BIWEEKLY,
            recurrence_day=0,  # Monday
            count=3,
        )
        assert dates[0] == date(2025, 6, 2)
        assert dates[1] == date(2025, 6, 16)
        assert dates[2] == date(2025, 6, 30)


class TestCalculateEventDatesMonthly:
    def test_monthly_basic(self):
        dates = calculate_event_dates(
            start_date=date(2025, 1, 15),
            recurrence_pattern=RecurrencePattern.MONTHLY,
            recurrence_day=15,
            count=4,
        )
        assert dates == [
            date(2025, 1, 15),
            date(2025, 2, 15),
            date(2025, 3, 15),
            date(2025, 4, 15),
        ]

    def test_monthly_day_31_clamps_in_short_months(self):
        """The core bug fix: day 31 should not crash in February."""
        dates = calculate_event_dates(
            start_date=date(2025, 1, 31),
            recurrence_pattern=RecurrencePattern.MONTHLY,
            recurrence_day=31,
            count=5,
        )
        assert dates == [
            date(2025, 1, 31),
            date(2025, 2, 28),  # Clamped
            date(2025, 3, 31),
            date(2025, 4, 30),  # Clamped
            date(2025, 5, 31),
        ]

    def test_monthly_day_31_leap_year(self):
        dates = calculate_event_dates(
            start_date=date(2024, 1, 31),
            recurrence_pattern=RecurrencePattern.MONTHLY,
            recurrence_day=31,
            count=3,
        )
        assert dates == [
            date(2024, 1, 31),
            date(2024, 2, 29),  # Leap year
            date(2024, 3, 31),
        ]

    def test_monthly_day_30_in_february(self):
        dates = calculate_event_dates(
            start_date=date(2025, 1, 30),
            recurrence_pattern=RecurrencePattern.MONTHLY,
            recurrence_day=30,
            count=3,
        )
        assert dates == [
            date(2025, 1, 30),
            date(2025, 2, 28),  # Clamped
            date(2025, 3, 30),
        ]

    def test_monthly_year_boundary(self):
        dates = calculate_event_dates(
            start_date=date(2025, 10, 15),
            recurrence_pattern=RecurrencePattern.MONTHLY,
            recurrence_day=15,
            count=5,
        )
        assert dates == [
            date(2025, 10, 15),
            date(2025, 11, 15),
            date(2025, 12, 15),
            date(2026, 1, 15),
            date(2026, 2, 15),
        ]

    def test_monthly_respects_end_date(self):
        dates = calculate_event_dates(
            start_date=date(2025, 1, 15),
            recurrence_pattern=RecurrencePattern.MONTHLY,
            recurrence_day=15,
            count=100,
            end_date=date(2025, 4, 1),
        )
        assert len(dates) == 3
        assert dates[-1] == date(2025, 3, 15)

    def test_monthly_respects_end_after_occurrences(self):
        dates = calculate_event_dates(
            start_date=date(2025, 1, 15),
            recurrence_pattern=RecurrencePattern.MONTHLY,
            recurrence_day=15,
            count=100,
            end_after_occurrences=3,
        )
        assert len(dates) == 3

    def test_monthly_start_after_recurrence_day(self):
        """If start_date is past the recurrence day, skip to next month."""
        dates = calculate_event_dates(
            start_date=date(2025, 1, 20),
            recurrence_pattern=RecurrencePattern.MONTHLY,
            recurrence_day=15,
            count=2,
        )
        assert dates == [
            date(2025, 2, 15),
            date(2025, 3, 15),
        ]
