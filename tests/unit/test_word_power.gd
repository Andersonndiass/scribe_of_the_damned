extends GutTest
## T048 O poder cresce com o tamanho da palavra (FR-018, Princípio VIII).


func test_power_budget_strictly_grows_with_length() -> void:
	var data: LexiconData = load("res://data/lexicon/base.tres")
	for a: WordData in data.words:
		for b: WordData in data.words:
			if a.latin.length() < b.latin.length():
				assert_lt(a.power_budget, b.power_budget,
					"%s (%d) deve ser mais fraca que %s (%d)" % [a.latin, a.latin.length(), b.latin, b.latin.length()])


func test_every_word_has_positive_power() -> void:
	var data: LexiconData = load("res://data/lexicon/base.tres")
	for w: WordData in data.words:
		assert_gt(w.power_budget, 0.0, w.latin)
