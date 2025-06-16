
coverage:
	@busted -c
	@luacov

clean:
	@rm -rf luacov.stats.out luacov.report.html
