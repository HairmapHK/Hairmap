import XCTest
@testable import Hairmap

@MainActor
final class HairmapModelTests: XCTestCase {
    func testSupabaseSettingsCanBeDisabledForUITesting() {
        let settings = SupabaseSettings.load(
            info: [
                "SUPABASE_URL": "https://example.supabase.co",
                "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_test",
                "SUPABASE_REDIRECT_URL": "hairmap://auth-callback"
            ],
            environment: ["HAIRMAP_DISABLE_SUPABASE": "1"],
            arguments: []
        )

        XCTAssertNil(settings)
    }

    func testSupabaseSettingsReadsEnvironmentAndRejectsMissingKeys() {
        let settings = SupabaseSettings.load(
            info: [
                "APP_ENVIRONMENT": "staging",
                "SUPABASE_URL": "https://example.supabase.co",
                "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_test",
                "SUPABASE_REDIRECT_URL": "hairmap://auth-callback"
            ],
            environment: [:],
            arguments: []
        )

        XCTAssertEqual(settings?.environment, "staging")
        XCTAssertEqual(settings?.url.absoluteString, "https://example.supabase.co")
        XCTAssertEqual(settings?.redirectURL.absoluteString, "hairmap://auth-callback")

        let missingKey = SupabaseSettings.load(
            info: [
                "SUPABASE_URL": "https://example.supabase.co",
                "SUPABASE_REDIRECT_URL": "hairmap://auth-callback"
            ],
            environment: [:],
            arguments: []
        )
        XCTAssertNil(missingKey)
    }

    func testStartChatFromStylistProfileSelectsThread() {
        var selectedTab = CustomerTab.discovery
        var customerPath: [CustomerRoute] = [.stylist("master-leo")]
        var selectedStylistID = "master-leo"
        var chatTargetStylistID: String?
        var chatTargetSalonID: String? = "salon-hair-kiss-2ba81bac"

        HairmapStore.applyCustomerChatRoute(
            stylistID: "alex-chen",
            selectedTab: &selectedTab,
            customerPath: &customerPath,
            selectedStylistID: &selectedStylistID,
            customerChatTargetStylistID: &chatTargetStylistID,
            customerSalonChatTargetSalonID: &chatTargetSalonID
        )

        XCTAssertEqual(selectedTab, .chat)
        XCTAssertEqual(selectedStylistID, "alex-chen")
        XCTAssertEqual(chatTargetStylistID, "alex-chen")
        XCTAssertNil(chatTargetSalonID)
        XCTAssertTrue(customerPath.isEmpty)
    }

    func testStylistDecodingKeepsBackwardsCompatibleDefaults() throws {
        let json = """
        {
          "id": "master-leo",
          "owner_id": null,
          "salon_id": "s1",
          "name": "Master Leo",
          "title": "首席設計師",
          "rating": 4.9,
          "reviews_count": 12,
          "languages": "中 / 英",
          "experience": "10年以上",
          "specialties": ["挑染專家", "經典剪髮"],
          "avatar_url": "https://example.com/avatar.jpg"
        }
        """.data(using: .utf8)!

        let stylist = try JSONDecoder().decode(Stylist.self, from: json)

        XCTAssertEqual(stylist.id, "master-leo")
        XCTAssertEqual(stylist.bio, "")
        XCTAssertEqual(stylist.basePrice, 0)
        XCTAssertTrue(stylist.isActive)
        XCTAssertFalse(stylist.isFeatured)
        XCTAssertEqual(stylist.displayOrder, 100)
        XCTAssertEqual(stylist.district, "")
        XCTAssertEqual(stylist.location, "")
        XCTAssertEqual(stylist.instagramURL, "")
        XCTAssertTrue(stylist.works.isEmpty)
        XCTAssertTrue(stylist.services.isEmpty)
        XCTAssertTrue(stylist.reviews.isEmpty)
    }

    func testSalonDecodingKeepsReviewDefaults() throws {
        let json = """
        {
          "id": "salon-hair-kiss-2ba81bac",
          "brand_id": "hair-kiss",
          "branch_name": "尖沙咀分店",
          "name": "Hair kiss",
          "location": "尖沙咀彌敦道",
          "district": "尖沙咀",
          "distance": 0.8,
          "rating": 4.9,
          "tags": ["日韓髮型"],
          "open_hours": "10:00 - 20:00",
          "phone": "+852 2345 6789",
          "instagram_url": "https://instagram.com/hairkiss",
          "start_price": 278,
          "image_url": "https://example.com/salon.jpg",
          "booking_enabled": true,
          "chat_enabled": true
        }
        """.data(using: .utf8)!

        let salon = try JSONDecoder().decode(Salon.self, from: json)

        XCTAssertEqual(salon.id, "salon-hair-kiss-2ba81bac")
        XCTAssertEqual(salon.reviewsCount, 0)
        XCTAssertTrue(salon.reviews.isEmpty)
        XCTAssertTrue(salon.bookingEnabled)
        XCTAssertTrue(salon.chatEnabled)
    }

    func testSalonReviewDecodingAllowsSalonTargetWithoutStylist() throws {
        let json = """
        {
          "id": "salon-review-1",
          "stylist_id": null,
          "salon_id": "salon-hair-kiss-2ba81bac",
          "reviewer_name": "Kelvin",
          "reviewer_avatar": "https://example.com/avatar.jpg",
          "text": "環境舒服，服務好細心。",
          "stars": 5,
          "time_ago": "剛剛",
          "review_photo_url": "https://example.com/review.jpg"
        }
        """.data(using: .utf8)!

        let review = try JSONDecoder().decode(ReviewItem.self, from: json)

        XCTAssertEqual(review.stylistID, "")
        XCTAssertEqual(review.salonID, "salon-hair-kiss-2ba81bac")
        XCTAssertEqual(review.stars, 5)
        XCTAssertEqual(review.reviewPhotoURL, "https://example.com/review.jpg")
    }

    func testInspirationItemDecodingKeepsOptionalFeatureDefaults() throws {
        let json = """
        {
          "id": "look-1",
          "stylist_id": "master-leo",
          "title": "銀灰精靈短髮",
          "salon_name": "Julian's Studio",
          "location": "深圳",
          "tags": ["銀灰髮", "短髮造型"],
          "image_url": "https://example.com/look.jpg",
          "category": "熱門"
        }
        """.data(using: .utf8)!

        let item = try JSONDecoder().decode(InspirationItem.self, from: json)

        XCTAssertEqual(item.title, "銀灰精靈短髮")
        XCTAssertEqual(item.authorName, "")
        XCTAssertTrue(item.mediaURLs.isEmpty)
        XCTAssertTrue(item.mediaKinds.isEmpty)
        XCTAssertEqual(item.likeCount, 0)
        XCTAssertEqual(item.commentCount, 0)
        XCTAssertEqual(item.shareCount, 0)
        XCTAssertFalse(item.isUserPost)
    }

    func testCatalogApplicationsConvertBackToPublicModels() {
        let submitterID = UUID()
        let service = ServiceItem(
            id: "service-cut",
            stylistID: "stylist-new",
            name: "招牌剪髮",
            category: "剪髮",
            duration: 60,
            description: "含洗髮與造型",
            price: 380
        )
        let work = PortfolioWork(
            id: "work-1",
            stylistID: "stylist-new",
            title: "日系剪裁",
            imageURL: "https://example.com/work.jpg"
        )
        let stylist = Stylist(
            id: "stylist-new",
            salonID: "salon-new",
            district: "尖沙咀",
            location: "尖沙咀海港城3樓3045號舖",
            name: "New Stylist",
            title: "設計師",
            rating: 5,
            reviewsCount: 0,
            languages: "中 / 英",
            experience: "5年資歷",
            specialties: ["日系剪裁"],
            avatarURL: "https://example.com/avatar.jpg",
            instagramURL: "@newstylist",
            bio: "擅長自然層次。",
            basePrice: 380,
            works: [work],
            services: [service]
        )

        let stylistApplication = StylistApplication(id: "app-1", submittedBy: submitterID, stylist: stylist)
        let publicStylist = stylistApplication.asStylist()

        XCTAssertEqual(stylistApplication.status, .pending)
        XCTAssertEqual(publicStylist.ownerID, submitterID)
        XCTAssertEqual(publicStylist.services, [service])
        XCTAssertEqual(publicStylist.works, [work])
        XCTAssertEqual(publicStylist.district, "尖沙咀")
        XCTAssertEqual(publicStylist.location, "尖沙咀海港城3樓3045號舖")
        XCTAssertEqual(publicStylist.instagramURL, "@newstylist")
        XCTAssertTrue(publicStylist.isActive)
        XCTAssertFalse(publicStylist.isFeatured)

        let salon = Salon(
            id: "salon-new",
            name: "New Salon",
            location: "中環皇后大道中88號",
            district: "中環",
            distance: 1.2,
            rating: 5,
            tags: ["日系剪裁"],
            openHours: "10:00 - 20:00",
            phone: "+852 2345 6789",
            instagramURL: "https://instagram.com/newsalon",
            startPrice: 1200,
            imageURL: "https://example.com/salon.jpg"
        )
        let salonApplication = SalonApplication(id: "salon-app-1", submittedBy: submitterID, salon: salon, works: [work])
        let publicSalon = salonApplication.asSalon()

        XCTAssertEqual(salonApplication.status, .pending)
        XCTAssertEqual(salonApplication.worksPayload, [work])
        XCTAssertEqual(publicSalon.id, "salon-new")
        XCTAssertEqual(publicSalon.district, "中環")
        XCTAssertEqual(publicSalon.location, "中環皇后大道中88號")
        XCTAssertEqual(publicSalon.instagramURL, "https://instagram.com/newsalon")
        XCTAssertTrue(publicSalon.isActive)
        XCTAssertFalse(publicSalon.isFeatured)
    }

    func testPortfolioWorkDecodingSupportsPhotoDefaultsAndVideoMetadata() throws {
        let legacyJSON = """
        {
          "id": "work-photo",
          "stylist_id": "stylist-new",
          "title": "日系剪裁",
          "image_url": "https://example.com/photo.jpg"
        }
        """.data(using: .utf8)!
        let legacyWork = try JSONDecoder().decode(PortfolioWork.self, from: legacyJSON)

        XCTAssertEqual(legacyWork.mediaKind, .photo)
        XCTAssertEqual(legacyWork.displayImageURL, "https://example.com/photo.jpg")
        XCTAssertFalse(legacyWork.isVideo)

        let videoJSON = """
        {
          "id": "work-video",
          "stylist_id": "stylist-new",
          "title": "漂染完成短片",
          "image_url": "https://example.com/poster.jpg",
          "media_kind": "video",
          "video_url": "https://example.com/video.mp4",
          "thumbnail_url": "https://example.com/thumb.jpg"
        }
        """.data(using: .utf8)!
        let videoWork = try JSONDecoder().decode(PortfolioWork.self, from: videoJSON)

        XCTAssertEqual(videoWork.mediaKind, .video)
        XCTAssertEqual(videoWork.displayImageURL, "https://example.com/thumb.jpg")
        XCTAssertEqual(videoWork.playableVideoURL, "https://example.com/video.mp4")
        XCTAssertTrue(videoWork.isVideo)
    }

    func testInstagramLinksNormalizeForAppAndWebOpen() {
        XCTAssertEqual(
            HairmapExternalLinks.normalizedInstagramWebURL(from: "@hairmaphk")?.absoluteString,
            "https://www.instagram.com/hairmaphk"
        )
        XCTAssertEqual(
            HairmapExternalLinks.instagramAppURL(from: "https://www.instagram.com/hairmaphk/")?.absoluteString,
            "instagram://user?username=hairmaphk"
        )
        XCTAssertEqual(HairmapExternalLinks.instagramDisplayText(from: "instagram.com/hairmap.hk"), "@hairmap.hk")
    }
}
