#include "testing/testing.hpp"

#include "generator/osm_id.hpp"
#include "generator/restrictions.hpp"

#include "coding/file_name_utils.hpp"

#include "platform/platform_tests_support/scoped_dir.hpp"
#include "platform/platform_tests_support/scoped_file.hpp"

#include "platform/platform.hpp"

#include "std/string.hpp"
#include "std/vector.hpp"

using namespace platform;
using namespace platform::tests_support;

string const kRestrictionTestDir = "test-restrictions";

UNIT_TEST(RestrictionTest_ValidCase)
{
  RestrictionCollector restrictionCollector("", "");
  // Adding restrictions and feature ids to restrictionCollector in mixed order.
  restrictionCollector.AddRestriction(RestrictionCollector::Type::No, {1, 2} /* osmIds */);
  restrictionCollector.AddFeatureId(30 /* featureId */, {3} /* osmIds */);
  restrictionCollector.AddRestriction(RestrictionCollector::Type::No, {2, 3} /* osmIds */);
  restrictionCollector.AddFeatureId(10 /* featureId */, {1} /* osmIds */);
  restrictionCollector.AddFeatureId(50 /* featureId */, {5} /* osmIds */);
  restrictionCollector.AddRestriction(RestrictionCollector::Type::Only, {5, 7} /* osmIds */);
  restrictionCollector.AddFeatureId(70 /* featureId */, {7} /* osmIds */);
  restrictionCollector.AddFeatureId(20 /* featureId */, {2} /* osmIds */);

  // Composing restriction in feature id terms.
  restrictionCollector.ComposeRestrictions();
  restrictionCollector.RemoveInvalidRestrictions();

  // Checking the result.
  TEST(restrictionCollector.IsValid(), ());

  vector<RestrictionCollector::Restriction> const expectedRestrictions =
  {{RestrictionCollector::Type::No, {10, 20}},
   {RestrictionCollector::Type::No, {20, 30}},
   {RestrictionCollector::Type::Only, {50, 70}}};
  TEST_EQUAL(restrictionCollector.m_restrictions, expectedRestrictions, ());
}

UNIT_TEST(RestrictionTest_InvalidCase)
{
  RestrictionCollector restrictionCollector("", "");
  restrictionCollector.AddFeatureId(0 /* featureId */, {0} /* osmIds */);
  restrictionCollector.AddRestriction(RestrictionCollector::Type::No, {0, 1} /* osmIds */);
  restrictionCollector.AddFeatureId(20 /* featureId */, {2} /* osmIds */);

  restrictionCollector.ComposeRestrictions();

  TEST(!restrictionCollector.IsValid(), ());

  vector<RestrictionCollector::Restriction> const expectedRestrictions =
      {{RestrictionCollector::Type::No, {0, RestrictionCollector::kInvalidFeatureId}}};
  TEST_EQUAL(restrictionCollector.m_restrictions, expectedRestrictions, ());

  restrictionCollector.RemoveInvalidRestrictions();
  TEST(restrictionCollector.m_restrictions.empty(), ());
  TEST(!restrictionCollector.IsValid(), ());
}

UNIT_TEST(RestrictionTest_ParseRestrictions)
{
  string const kRestrictionName = "restrictions_in_osm_ids.csv";
  string const kRestrictionPath = my::JoinFoldersToPath(kRestrictionTestDir, kRestrictionName);
  string const kRestrictionContent = R"(No, 1, 1,
                                        Only, 0, 2,
                                        Only, 2, 3,
                                        No, 38028428, 38028428,
                                        No, 4, 5,)";

  ScopedDir const scopedDir(kRestrictionTestDir);
  ScopedFile const scopedFile(kRestrictionPath, kRestrictionContent);

  RestrictionCollector restrictionCollector("", "");

  Platform const & platform = Platform();

  TEST(restrictionCollector.ParseRestrictions(my::JoinFoldersToPath(platform.WritableDir(),
                                                                    kRestrictionPath)), ());
  vector<RestrictionCollector::Restriction> expectedRestrictions =
      {{RestrictionCollector::Type::No, 2},
       {RestrictionCollector::Type::Only, 2},
       {RestrictionCollector::Type::Only, 2},
       {RestrictionCollector::Type::No, 2},
       {RestrictionCollector::Type::No, 2}};
  TEST_EQUAL(restrictionCollector.m_restrictions, expectedRestrictions, ());

  vector<pair<uint64_t, RestrictionCollector::Index>> const expectedRestrictionIndex =
      {{1, {0, 0}}, {1, {0, 1}},
       {0, {1, 0}}, {2, {1, 1}},
       {2, {2, 0}}, {3, {2, 1}},
       {38028428, {3, 0}}, {38028428, {3, 1}},
       {4, {4, 0}}, {5, {4, 1}}};
  TEST_EQUAL(restrictionCollector.m_restrictionIndex, expectedRestrictionIndex, ());
}

UNIT_TEST(RestrictionTest_ParseFeatureId2OsmIdsMapping)
{
  string const kFeatureIdToOsmIdsName = "feature_id_to_osm_ids.csv";
  string const kFeatureIdToOsmIdsPath = my::JoinFoldersToPath(kRestrictionTestDir, kFeatureIdToOsmIdsName);
  string const kFeatureIdToOsmIdsContent = R"(1, 10,
                                              2, 20,
                                              779703, 5423239545,
                                              3, 30)";

  ScopedDir const scopedDir(kRestrictionTestDir);
  ScopedFile const scopedFile(kFeatureIdToOsmIdsPath, kFeatureIdToOsmIdsContent);

  RestrictionCollector restrictionCollector("", "");

  Platform const & platform = Platform();
  restrictionCollector.ParseFeatureId2OsmIdsMapping(my::JoinFoldersToPath(platform.WritableDir(),
                                                                          kFeatureIdToOsmIdsPath));

  vector<pair<uint64_t, RestrictionCollector::FeatureId>> const expectedOsmIds2FeatureId =
     {{10, 1}, {20, 2}, {5423239545, 779703}, {30, 3}};
  vector<pair<uint64_t, RestrictionCollector::FeatureId>> const osmIds2FeatureId(
        restrictionCollector.m_osmIds2FeatureId.cbegin(), restrictionCollector.m_osmIds2FeatureId.cend());
  TEST_EQUAL(osmIds2FeatureId, expectedOsmIds2FeatureId, ());
}

UNIT_TEST(RestrictionTest_RestrictionCollectorWholeClassTest)
{
  string const kRestrictionName = "restrictions_in_osm_ids.csv";
  string const kRestrictionPath = my::JoinFoldersToPath(kRestrictionTestDir, kRestrictionName);
  string const kRestrictionContent = R"(No, 10, 10,
                                        Only, 10, 20,
                                        Only, 30, 40,)";

  string const kFeatureIdToOsmIdsName = "feature_id_to_osm_ids.csv";
  string const kFeatureIdToOsmIdsPath = my::JoinFoldersToPath(kRestrictionTestDir, kFeatureIdToOsmIdsName);
  string const kFeatureIdToOsmIdsContent = R"(1, 10,
                                              2, 20,
                                              3, 30,
                                              4, 40)";

  ScopedDir scopedDir(kRestrictionTestDir);
  ScopedFile restrictionScopedFile(kRestrictionPath, kRestrictionContent);
  ScopedFile mappingScopedFile(kFeatureIdToOsmIdsPath, kFeatureIdToOsmIdsContent);

  Platform const & platform = Platform();
  RestrictionCollector restrictionCollector(my::JoinFoldersToPath(platform.WritableDir(), kRestrictionPath),
                                            my::JoinFoldersToPath(platform.WritableDir(), kFeatureIdToOsmIdsPath));
  TEST(restrictionCollector.IsValid(), ());

  vector<RestrictionCollector::Restriction> const expectedRestrictions =
      {{RestrictionCollector::Type::No, {1, 1}},
       {RestrictionCollector::Type::Only, {1, 2}},
       {RestrictionCollector::Type::Only, {3, 4}}};
  TEST_EQUAL(restrictionCollector.GetRestriction(), expectedRestrictions, ());
}
