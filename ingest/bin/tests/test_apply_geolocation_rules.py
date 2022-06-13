from ..apply_geolocation_rules import load_geolocation_rules, get_annotated_geolocation


def write_file_with_lines(tmpdir, lines):
    """Write a file `test_file.txt` with the provided lines."""
    geolocation_rules_file = tmpdir.join("test_file.txt")
    with open(geolocation_rules_file, 'w') as f:
            f.write('\n'.join(lines))
    return geolocation_rules_file


def get_geolocation_rules(tmpdir, lines):
    """Get geolocation rules from the provided lines."""
    geolocation_rules_file = write_file_with_lines(tmpdir, lines)
    return load_geolocation_rules(geolocation_rules_file)


class TestLoadGeolocationRules:
    "Tests for loading geolocation rules files."

    def test_load_with_comment(self, tmpdir):
        """Test that a line starting with `#` is skipped."""
        lines = (
            "# This is a comment",
        )
        geolocation_rules_file = write_file_with_lines(tmpdir, lines)
        geolocation_rules = load_geolocation_rules(geolocation_rules_file)
        assert geolocation_rules == {}

    def test_load_with_inline_comment(self, tmpdir):
        """Test that `#` and any following characters are treated as an inline comment."""
        lines = (
            "a/b/c/d\t1/2/3/4 # this is a comment",
            "a/b/c/e\t1/2/3/# 4 this is a comment",
        )
        geolocation_rules_file = write_file_with_lines(tmpdir, lines)
        geolocation_rules = load_geolocation_rules(geolocation_rules_file)
        assert geolocation_rules["a"]["b"]["c"]["d"] == ("1", "2", "3", "4")
        assert geolocation_rules["a"]["b"]["c"]["e"] == ("1", "2", "3", "")

    def test_load_with_wildcard_character(self, tmpdir):
        """Test that `*` characters can be loaded."""
        lines = (
            "a/b/*/*\t1/2/*/*",
            "a/b/c/*\t1/2/3/4",
        )
        geolocation_rules_file = write_file_with_lines(tmpdir, lines)
        geolocation_rules = load_geolocation_rules(geolocation_rules_file)
        assert geolocation_rules["a"]["b"]["*"]["*"] == ("1", "2", "*", "*")
        assert geolocation_rules["a"]["b"]["c"]["*"] == ("1", "2", "3", "4")

    def test_load_with_empty(self, tmpdir):
        """Test that an empty field can be loaded in the raw and/or annotated column."""
        lines = (
            "a/b//\ta/b/c/d",
            "a/b/c/d\ta/b//",
            "a/c//\ta/b//",
        )
        geolocation_rules_file = write_file_with_lines(tmpdir, lines)
        geolocation_rules = load_geolocation_rules(geolocation_rules_file)
        assert geolocation_rules["a"]["b"][""][""] == ("a", "b", "c", "d")
        assert geolocation_rules["a"]["b"]["c"]["d"] == ("a", "b", "", "")
        assert geolocation_rules["a"]["c"][""][""] == ("a", "b", "", "")


class TestGetAnnotatedGeolocation:
    "Tests for getting an annotated geolocation."

    def test_simple_rule(self, tmpdir):
        """Test that a simple rule works."""
        lines = (
            "a/b/c/d\t1/2/3/4",
        )
        geolocation_rules = get_geolocation_rules(tmpdir, lines)
        assert get_annotated_geolocation(geolocation_rules, ("a", "b", "c", "d")) == ("1", "2", "3", "4")

    def test_none_if_no_matching_rule(self, tmpdir):
        """Test that `None` is returned when there is no matching rule."""
        lines = (
            "a/b/c/d\t1/2/3/4",
        )
        geolocation_rules = get_geolocation_rules(tmpdir, lines)
        assert get_annotated_geolocation(geolocation_rules, ("a", "a", "a", "a")) is None
