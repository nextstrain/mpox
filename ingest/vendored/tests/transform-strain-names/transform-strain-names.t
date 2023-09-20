Look for strain name in "strain" or a list of backup fields.

If strain entry exists, do not do anything.

  $ echo '{"strain": "i/am/a/strain", "strain_s": "other"}' \
  >   | $TESTDIR/../../transform-strain-names \
  >       --strain-regex '^.+$' \
  >       --backup-fields strain_s accession
  {"strain":"i/am/a/strain","strain_s":"other"}

If strain entry does not exists, search the backup fields

  $ echo '{"strain_s": "other"}' \
  >   | $TESTDIR/../../transform-strain-names \
  >       --strain-regex '^.+$' \
  >       --backup-fields accession strain_s 
  {"strain_s":"other","strain":"other"}