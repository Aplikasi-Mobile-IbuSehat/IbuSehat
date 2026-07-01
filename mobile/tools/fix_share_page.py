path = r"c:\Users\User\Documents\PBL SMSTR 4\IbuSehat-1\mobile\lib\pages\beranda\share_achievement_page.dart"

with open(path, "r", encoding="utf-8") as f:
    content = f.read()

replacements = [
    (
        "'Aku konsisten ${widget.streakDays} hari penuh menjaga kesehatan di IbuSehat! '",
        "'Aku konsisten $_effectiveStreakDays hari penuh menjaga kesehatan di IbuSehat! '",
    ),
    (
        "child: _AchievementShareCard(streakDays: widget.streakDays),",
        "child: _AchievementShareCard(streakDays: _effectiveStreakDays),",
    ),
    (
        "${directory.path}/ibusehat_streak_${widget.streakDays}.png",
        "${directory.path}/ibusehat_streak_$_effectiveStreakDays.png",
    ),
    (
        "name: 'IbuSehat_Streak_${widget.streakDays}',",
        "name: 'IbuSehat_Streak_$_effectiveStreakDays',",
    ),
]

for old, new in replacements:
    if old not in content:
        print(f"MISSING: {old[:60]}...")
    else:
        content = content.replace(old, new)
        print(f"OK: {old[:40]}...")

old_body = """      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            children: [
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxCardHeight),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topCenter,
                    child: Screenshot(
                      controller: _screenshotController,
                      child: _AchievementShareCard(streakDays: widget.streakDays),
                    ),
                  ),
                ),
              ),"""

new_body = """      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxCardHeight),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: constraints.maxWidth,
                        child: Screenshot(
                          controller: _screenshotController,
                          child: _AchievementShareCard(
                            streakDays: _effectiveStreakDays,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),"""

if old_body not in content:
    print("OLD BODY NOT FOUND - checking if already fixed")
    if "LayoutBuilder" in content and "_effectiveStreakDays" in content:
        print("Already fixed")
    else:
        raise SystemExit(1)
else:
    content = content.replace(old_body, new_body)
    print("Body replaced OK")

if "_effectiveStreakDays" not in content:
    insert_after = "  bool _isProcessing = false;\n"
    insert = insert_after + (
        "\n"
        "  int get _effectiveStreakDays =>\n"
        "      widget.streakDays > 0 ? widget.streakDays : 5;\n"
    )
    if insert_after in content:
        content = content.replace(insert_after, insert)
        print("Added _effectiveStreakDays getter")

with open(path, "w", encoding="utf-8", newline="\n") as f:
    f.write(content)

print("Done")
