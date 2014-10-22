Notes for testing the infodeck software

Since much of the complexity of the infodeck software comes from coordinating the loading of fragments of the deck into the DOM, I had trouble getting a decent test environment going (well that and lack of experience with the js/web stack).

The best automated tests come via mocha. Use the `rake infodeck:mocha` task to build the deck and `rake infodeck:mocha_server` to launch the server to use it. The mocha tests exercise various areas of the infodeck software. 

I ought to get a manual deck that exposes much of the areas of infodecks where there is awkward bits, but I haven't done anything with that yet.

The `infodeck:visual` task was something of a start on that, mostly used so far to help in assessing some sizing issues with omnigraffle svgs. It's not much yet, indeed not enough to be worth bothering much with, but I may expand on this later.
