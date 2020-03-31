# Try it
```
bundle install
ruby diff.rb
```

The export here had it's patient's last name dropped, social security value messed up, their first name duplicated and re-ordered down a few elements. Text diffy vs MVP diff:
![text](https://github.com/dompham/xml-diff-spike/blob/master/img/text_diffy.png)
![logical](https://github.com/dompham/xml-diff-spike/blob/master/img/xml_differ.png)


#### Import/Export Diff Spike
  Ask: Explore a better way to validate our import/export output.  A better diffy?

Proposal: I think that the best way to go about this would be to do it "logically", instead of textually.  I think by comparing Nodes instead of Text, we skip some of the complexities of XML, for instance, attribute order. After brief analysis on some other directions I decided to try my hand at how this might be done. The idea that I MVP'd here in this repo is tackling the comparisons after Hashifying the XML documents.  Any of the dependencies I used, I believe that we can home-grow if they're too stiff.

MVP Features:
- Hashify and compare 2 XML nodes (doesn't have to be root level).
- Diffs will be logged in a list for post-processing.
- **Does not handle Node Presence well**

**At this moment, I recommend revisting our acceptance criteria to discuss "win" priority.  I do believe we can make a better validator than diffy, but I'm not sure if it'll be what we currently imagine, when taking into account the technical challenges listed below.**
#### Tech notes:
- I'm using Nori to hashify the XML due to high praise from StackOverflow, but I believe that Nokogiri has similar functionality built in
- I'm using a deep sort to disregard order of elements, because if an element has more than 1 child, they are represented as an array in the hash.  This has proven to be a double edged sword, more details in the section below
- After getting 2 hashes, I'm going to use a gem and recursively diff the Hashes together.
- The recursive diff method allows for a block to be passed in for custom comparisons, somethign that I think will be very valuable
- For every diff found, a log list is pushed into an instance var.  The structure of the list is:
    - `[symbol, path, expected, got(if needed)]`
    - Symbol represents the 3 possible result flags: `~`, `+`, and `-`, which represent value difference, unexpected and missing respectively
    - Path represents a dot notation for where in the XML this log is referencing
    - Ex: If an element is missing in the patient of an export might look like: `[-, document.patient.value, <element />]`
- After returning a list of log lists, I run that list through a post-processing method just for pretty printing

#### Technical Difficulties
After analyzing some different approaches, some common difficulties were present across the different strategies.  The list below is written in order of what I consider greatest pain in our butts - with a proposed solution(compromise?) to each:
- **Presence**:  The more I read, the more the idea of "node presence" haunted me.  Testing node presence is the ability to differ between whether or not you believe that your nodeset is malformed or straight up *missing*.  This is why most if not all XML libraries short circuit their validations, because of cascading errors.
    ```
    <parent>
      <child1>
        <gchild1 />
      </child1>
      <child2>
        <gchild2 />
      </child2>
    </parent>
    ```
    - For example: If `child2` is different between the import and export files, how would we be able to tell if it's *actually* `child2` that's different and not completely missing and replaced with a totally different element?  Should we take note of it and keep recursing? What if there are 3 children and the middle one is missing AND the last one is different?  How do we ensure that the "third" one gets compared appropriately and not against the missing second one?
    - Suggestion: Although suboptimal, I believe there are great solutions out there (this one included) that leverage short circuiting, while doing a breadth first comparison.  The MVP here will tell you the exact path to where your highest issues are

- **Short Circuiting**: The downside with short circuiting of course, is the lack of a one time comprehensive report
    - Solution: We can try to give the most comprehensive results by semi-short circuiting, only down that parent's tree.  This way, one parent having a diff doesn't affect unrelated parents, we can still give a list of parents with issues and point out where/what we think the issue is. If there is some kind of UID that exists on elements (maybe we can make them up?), this certainly gets easier. This work is not in this MVP, but I thikn it deserves its own mini-spike.
- **Ordering**: Since XML represents data nodes, it usually doesn't care about what order the nodes are in, as long as they belong to the appropriate parent.  This alone eliminates nearly any single gem for XML String comparisons
    - Suggestion: Dont compare strings, at least not at a parent level

#### Alternative Strategy
- Comparison by deletion: In a separate branch I tried forking a gem called equivalent-xml that uses a recursive node-deletion strategy to determine equivalency.  It recurses down and starts finding nodes from XML1 and deleting it from XML2.  XMLs are "equivalent" if at the end, XML2 is empty.  This alternative was interesting, especially after I added more logging to make it diff instead of only boolean testing, but it runs into the same Presence issues as listed above.  Not being able to delete a parent from XML2 will render that specific hierarchy `invalid`, which is fine for a validator - not so fine for a differ
- Import Coverage: Similarly to our testing coverage, as import goes through the XML file, it keeps track of what its seen.  Afterwards, we can return a report so show the importer what was taken into account or not.  This approach doesn't really validate that things were imported properly + it requires human interaction constantly because not all elements are parsed for import, so you'll always miss some level of coverage.
