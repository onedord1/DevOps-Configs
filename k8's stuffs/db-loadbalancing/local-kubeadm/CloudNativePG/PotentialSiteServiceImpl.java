package aesl.corteza.disbursement_be.potential_site.service.impl;

import aesl.corteza.disbursement_be.client.entity.*;
import aesl.corteza.disbursement_be.client.repositories.IHBRegistrationRepository;
import aesl.corteza.disbursement_be.client.service.ClientService;
import aesl.corteza.disbursement_be.common.Utils;
import aesl.corteza.disbursement_be.common.exception.AesException;
import aesl.corteza.disbursement_be.competitor.repository.CompetitorRepository;
import aesl.corteza.disbursement_be.master_settings.demarcation_module.bazaar.entity.Bazaar;
import aesl.corteza.disbursement_be.master_settings.demarcation_module.bazaar.repository.BazaarRepository;
import aesl.corteza.disbursement_be.master_settings.nation_module.nation.util.CustomStatus;
import aesl.corteza.disbursement_be.organization.dto.SiteForVisitProjection;
import aesl.corteza.disbursement_be.potential_site.dto.*;
import aesl.corteza.disbursement_be.potential_site.entity.PotentialSite;
import aesl.corteza.disbursement_be.potential_site.entity.SiteDealerType;
import aesl.corteza.disbursement_be.potential_site.repository.PotentialSiteRepository;
import aesl.corteza.disbursement_be.potential_site.service.PotentialSiteService;
import aesl.corteza.disbursement_be.product.entity.Brand;
import aesl.corteza.disbursement_be.product.repository.BrandRepository;
import aesl.corteza.disbursement_be.user.User;
import aesl.corteza.disbursement_be.user.dto.TerritoryDto;
import aesl.corteza.disbursement_be.user.dto.TerritoryInfo;
import aesl.corteza.disbursement_be.user.dto.UserResponseDto;
import aesl.corteza.disbursement_be.user.service.UserService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.function.Function;
import java.util.function.ToLongFunction;

import static aesl.corteza.disbursement_be.potential_site.entity.PartnerType.*;


@Slf4j
@Service
@RequiredArgsConstructor
public class PotentialSiteServiceImpl implements PotentialSiteService {

    public static final String POTENTIAL_SITE = "potentialSite";
    public static final String PHONE = "projectContactNumber";
    public static final String STATUS = "status";
    public static final String IHB_NAME = "ihbName";
    private static final Integer PAGE = 0;
    private static final Integer SIZE = 20;
    private final PotentialSiteRepository potentialSiteRepository;
    private final ClientService clientService;
    private final BazaarRepository bazaarRepository;
    private final UserService userService;
    private final IHBRegistrationRepository ihbRegistrationRepository;
    private final Utils utils;
    private final BrandRepository brandRepository;

    private final CompetitorRepository competitorRepository;

    private static final String BRAND_NOT_FOUND = "Brand not found by given id: ";
    private static final String IHB_NOT_FOUND = "IHB not found by given id: ";


    @Override
    @Transactional
    public PotentialSite createPotentialSite(PotentialSiteDto potentialSiteDto) {
        PotentialSite potentialSite = new PotentialSite();
        try {
            User user = userService.getLoggedInUser();

            potentialSite.setAddress(potentialSiteDto.getAddress())
                    .setEndStage(potentialSiteDto.getEndStage())
                    .setEstVolCmt(potentialSiteDto.getEstVolCmt() != null ? Integer.valueOf(potentialSiteDto.getEstVolCmt()) : null)
                    .setEstVolIspat(potentialSiteDto.getEstVolIspat())
                    .setIspatTerritoryName(potentialSiteDto.getIspatTerritoryName())
                    .setIspatTerritoryRecordRef(potentialSiteDto.getIspatTerritoryRecordRef())
                    .setIspatTerritoryTableId(potentialSiteDto.getIspatTerritoryTableId())
                    .setNotes(potentialSiteDto.getNotes())
                    .setPotentialSite(potentialSiteDto.getPotentialSite())
                    .setRefEngineer(potentialSiteDto.getRefEngineer())
                    .setSiteType(potentialSiteDto.getSiteType())
                    .setStartStage(potentialSiteDto.getStartStage())
                    .setVisitPhoto(potentialSiteDto.getVisitPhoto())
                    .setStatus(potentialSiteDto.getStatus())
                    .setCompetitorName(potentialSiteDto.getCompetitorName())
                    .setCreatedBy(user.getId())
                    .setUpdatedBy(user.getId());

            Optional<Bazaar> bazaar = bazaarRepository.findById(potentialSiteDto.getBazaar());

            if (bazaar.isPresent()) {
                potentialSite.setBazaar(bazaar.get());
            }

            Optional<IHBRegistration> ihb = Optional.empty();
            if (potentialSiteDto.getIhb() != null) {
                ihb = ihbRegistrationRepository.findById(potentialSiteDto.getIhb());
            }


            if (ihb.isPresent()) {
                potentialSite.setIhb(ihb.get())
                .setProjectContactNumber(ihb.get().getPhone())
                .setProjectContactName(ihb.get().getName());
            }

            if (potentialSiteDto.getPartnerType() != null) {
                potentialSite.setPartnerType(potentialSiteDto.getPartnerType());

                if (potentialSiteDto.getPartnerType().contains(HEAD_MASON.toString())) {
                    HeadMason headMason = clientService.findHeadMasonById(potentialSiteDto.getHeadMason());
                    potentialSite.setHeadMason(headMason);
                }
                if (potentialSiteDto.getPartnerType().contains(CONTRACTOR.toString())) {
                    Contractor contractor = clientService.findContractorById(potentialSiteDto.getContractor());
                    potentialSite.setContractor(contractor);
                }
                if (potentialSiteDto.getPartnerType().contains(SITE_MANAGER.toString())) {
                    SiteManager siteManager = clientService.findSiteManagerById(potentialSiteDto.getSiteManager());
                    potentialSite.setSiteManager(siteManager);

                }

            }
            if (potentialSiteDto.getEngineerRef() != null) {
                Engineer engineer = clientService.getEngineerById(potentialSiteDto.getEngineerRef());
                potentialSite.setEngineer(engineer);
            }

            potentialSite.setCementDealerType(SiteDealerType.valueOf(potentialSiteDto.getCementDealerType()))
            .setCementDealerName(potentialSiteDto.getCementDealerName())
            .setCementBrand(getCompetitorOrThrow(potentialSiteDto.getCementBrand()))
            .setIspatDealerType(SiteDealerType.valueOf(potentialSiteDto.getIspatDealerType()))
            .setIspatDealerName(potentialSiteDto.getIspatDealerName())
            .setIspatBrand(getCompetitorOrThrow(potentialSiteDto.getIspatBrand()));

            potentialSite = potentialSiteRepository.save(potentialSite);

            return potentialSite;
        } catch (Exception e) {
            log.error("Potential project saving error :: {}", e.getMessage());
            throw new AesException("Potential project saving error: " + e.getMessage());
        }
    }

    public Page<PotentialSiteRepository.ListPotentialSite> getMyPotentialSite(int page, int size, String searchParamKey, String searchParamValue) {
        Sort sort = Sort.by(Sort.Direction.DESC, "id");
        Pageable pageable = PageRequest.of(page, size, sort);

        Set<Long> bazaars = utils.resolveAccessibleBazaarIds(userService.getLoggedInUser());
        if (bazaars == null || bazaars.isEmpty()) {
            throw new AesException("No accessible bazaars found for the logged-in user.");
        }
        Long[] bazaarIds = bazaars.toArray(new Long[0]);
        boolean shouldBazaarFilterApply = true;

        if (searchParamValue != null && !searchParamValue.isBlank()) {
            switch (searchParamKey) {
                case POTENTIAL_SITE:
                    return potentialSiteRepository.fetchMyPotentialSite(
                            searchParamValue,
                            null,
                            null,
                            null,
                            bazaarIds,
                            shouldBazaarFilterApply,
                            pageable);
                case IHB_NAME:
                    return potentialSiteRepository.fetchMyPotentialSite(
                            null,
                            null,
                            searchParamValue,
                            null,
                            bazaarIds,
                            shouldBazaarFilterApply,
                            pageable);
                case PHONE:
                    return potentialSiteRepository.fetchMyPotentialSite(
                            null,
                            searchParamValue,
                            null,
                            null,
                            bazaarIds,
                            shouldBazaarFilterApply,
                            pageable);
                case STATUS:
                    return potentialSiteRepository.fetchMyPotentialSite(
                            null,
                            null,
                            null,
                            searchParamValue,
                            bazaarIds,
                            shouldBazaarFilterApply,
                            pageable);
                default:
                    break;
            }
        }

        return potentialSiteRepository.fetchMyPotentialSite(
                null,
                null,
                null,
                null,
                bazaarIds,
                shouldBazaarFilterApply,
                pageable);
    }

    public Page<PotentialSiteRepository.ListPotentialSite> getApprovedPotentialSite(
            Optional<Integer> page,
            Optional<Integer> size,
            Optional<Long> bdTerritoryId,
            Optional<Long> engineerId,
            Optional<String> ownerPhoneNumber) {

        Pageable pageable = PageRequest.of(page.orElse(PAGE), size.orElse(SIZE));
        return potentialSiteRepository.fetchPendingOrPotentialSites(
                bdTerritoryId.orElse(null),
                engineerId.orElse(null),
                ownerPhoneNumber.orElse(null),
                pageable);
    }

    public Page<PotentialSiteRepository.ListPotentialSite> getConvertedSite(
            Optional<Integer> page,
            Optional<Integer> size,
            Optional<Long> bdTerritoryId,
            Optional<Long> engineerId,
            Optional<String> ownerPhoneNumber) {

        Pageable pageable = PageRequest.of(page.orElse(PAGE), size.orElse(SIZE));
        return potentialSiteRepository.fetchConvertedSites(
                bdTerritoryId.orElse(null),
                engineerId.orElse(null),
                ownerPhoneNumber.orElse(null),
                pageable);
    }

    @Override
    public Page<ConvertedSiteProjection> getConvertedSiteProjection(Long bdTerritoryId, Long engineerId, String ownerPhoneNumber, Pageable pageable) {
        return potentialSiteRepository.getConvertedSitePage(pageable);
    }

    public List<PotentialSite> getMyPotentialSiteList(String searchParamKey, String searchParamValue) {
        return potentialSiteRepository.findAll();
    }

    public void deleteSiteById(Long id) {
        if (!potentialSiteRepository.existsById(id)) {
            throw new AesException("Potential Site with ID " + id + " not found.");
        }
        potentialSiteRepository.deleteById(id);
    }

    @Transactional(readOnly = true)
    public PotentialSiteResponseDto getPotentialSiteById(Long id) {
        PotentialSite potentialSite = potentialSiteRepository.findById(id)
                .orElseThrow(() -> new AesException("Potential Site with ID " + id + " not found."));

        Brand cement = getCompetitorBrandSafe(potentialSite.getCementBrand());
        Brand ispat = getCompetitorBrandSafe(potentialSite.getIspatBrand());

        PotentialSiteResponseDto potentialSiteResponseDto = new PotentialSiteResponseDto();

        potentialSiteResponseDto.setId(potentialSite.getId())
                .setCreatedAt(potentialSite.getCreatedAt())
                .setCreatedBy(potentialSite.getCreatedBy())
                .setUpdatedAt(potentialSite.getUpdatedAt())
                .setUpdatedBy(potentialSite.getUpdatedBy())
                .setSiteType(potentialSite.getSiteType())
                .setPotentialSite(potentialSite.getPotentialSite())
                .setSiteOwnerName(potentialSite.getSiteOwnerName())
                .setProjectContactNumber(potentialSite.getProjectContactNumber())
                .setAddress(potentialSite.getAddress())
                .setEstVolIspat(potentialSite.getEstVolIspat())
                .setEstVolCmt(potentialSite.getEstVolCmt())
                .setStoriedBuilding(potentialSite.getStoriedBuilding())
                .setStartStage(potentialSite.getStartStage())
                .setEndStage(potentialSite.getEndStage())
                .setEngineerType(potentialSite.getEngineerType())
                .setRefEngineer(potentialSite.getRefEngineer())
                .setNotes(potentialSite.getNotes())
                .setIspatTerritoryName(potentialSite.getIspatTerritoryName())
                .setIspatTerritoryTableId(potentialSite.getIspatTerritoryTableId())
                .setVisitPhoto(potentialSite.getVisitPhoto())
                .setStatus(potentialSite.getStatus())
                .setPartnerType(potentialSite.getPartnerType())
                .setHasOrderApproved(toStringOrNull(potentialSite.getHasOrderApproved()))
                .setEngineerRef(getId(potentialSite.getEngineer(), Engineer::getId))
                .setConsultedEngineer(getName(potentialSite.getEngineer(), Engineer::getName))
                .setSiteManager(getId(potentialSite.getSiteManager(), SiteManager::getId))
                .setSiteManagerName(getName(potentialSite.getSiteManager(), SiteManager::getName))
                .setContractor(getId(potentialSite.getContractor(), Contractor::getId))
                .setContractorName(getName(potentialSite.getContractor(), Contractor::getName))
                .setHeadMason(getId(potentialSite.getHeadMason(), HeadMason::getId))
                .setHeadMasonName(getName(potentialSite.getHeadMason(), HeadMason::getName))
                .setIhb(getId(potentialSite.getIhb(), IHBRegistration::getId))
                .setIhbName(getName(potentialSite.getIhb(), IHBRegistration::getName))
                .setBazaarId(getId(potentialSite.getBazaar(), Bazaar::getId))
                .setBazaarName(getName(potentialSite.getBazaar(), Bazaar::getBazaarName))
                .setCementDealerType(toStringOrNull(potentialSite.getCementDealerType()))
                .setCementDealerName(potentialSite.getCementDealerName())
                .setIspatDealerType(toStringOrNull(potentialSite.getIspatDealerType()))
                .setIspatDealerName(potentialSite.getIspatDealerName())
                .setCementBrand(getId(cement, Brand::getId))
                .setCementBrandName(getName(cement, Brand::getName))
                .setIspatBrand(getId(ispat, Brand::getId))
                .setIspatBrandName(getName(ispat, Brand::getName));

        return potentialSiteResponseDto;
    }

    private <T> Long getId(T entity, ToLongFunction<T> idGetter) {
        return entity != null ? idGetter.applyAsLong(entity) : null;
    }

    private <T> String getName(T entity, Function<T, String> nameGetter) {
        return entity != null ? nameGetter.apply(entity) : null;
    }

    private String toStringOrNull(Object obj) {
        return obj != null ? obj.toString() : null;
    }

    private Brand getCompetitorBrandSafe(Brand brand) {
        return Optional.ofNullable(brand)
                .map(b -> getCompetitorOrThrow(b.getId()))
                .orElse(null);
    }


    @Transactional
    public void updatePotentialSite(Long potentialSiteId, PotentialSiteDto potentialSiteDto) {
        PotentialSite potentialSite = potentialSiteRepository.findById(potentialSiteId)
                .orElseThrow(() -> new AesException("Potential site not found: " + potentialSiteId));

        try {

            potentialSite.setAddress(potentialSiteDto.getAddress())
                    .setEndStage(potentialSiteDto.getEndStage())
                    .setEngineerType(potentialSiteDto.getEngineerType())
                    .setEstVolCmt(potentialSiteDto.getEstVolCmt() != null ? Integer.valueOf(potentialSiteDto.getEstVolCmt()) : null)
                    .setEstVolIspat(potentialSiteDto.getEstVolIspat())
                    .setIspatTerritoryName(potentialSiteDto.getIspatTerritoryName())
                    .setIspatTerritoryRecordRef(potentialSiteDto.getIspatTerritoryRecordRef())
                    .setIspatTerritoryTableId(potentialSiteDto.getIspatTerritoryTableId())
                    .setNotes(potentialSiteDto.getNotes())
                    .setPotentialSite(potentialSiteDto.getPotentialSite())
                    .setProjectContactNumber(potentialSiteDto.getProjectContactNumber())
                    .setRefEngineer(potentialSiteDto.getRefEngineer())
                    .setSiteOwnerName(potentialSiteDto.getSiteOwnerName())
                    .setSiteType(potentialSiteDto.getSiteType())
                    .setStartStage(potentialSiteDto.getStartStage())
                    .setStoriedBuilding(potentialSiteDto.getStoriedBuilding())
                    .setVisitPhoto(potentialSiteDto.getVisitPhoto())
                    .setStatus(potentialSiteDto.getStatus())
                    .setCompetitorName(potentialSiteDto.getCompetitorName())
                    .setCementDealerType(SiteDealerType.valueOf(potentialSiteDto.getCementDealerType()))
                    .setCementBrand(getCompetitorOrThrow(potentialSiteDto.getCementBrand()))
                    .setCementDealerName(potentialSiteDto.getCementDealerName())
                    .setIspatDealerType(SiteDealerType.valueOf(potentialSiteDto.getIspatDealerType()))
                    .setIspatDealerName(potentialSiteDto.getIspatDealerName())
                    .setIspatBrand(getCompetitorOrThrow(potentialSiteDto.getIspatBrand()));

            if (potentialSiteDto.getIhb() != null) {
                IHBRegistration ihb = ihbRegistrationRepository.findById(potentialSiteDto.getIhb())
                        .orElseThrow(() -> new AesException(IHB_NOT_FOUND + potentialSiteDto.getIhb()));
                potentialSite.setIhb(ihb);
            } else {
                potentialSite.setIhb(null);
            }
            if (potentialSiteDto.getPartnerType() != null) {
                potentialSite.setPartnerType(potentialSiteDto.getPartnerType());
                if (potentialSiteDto.getPartnerType().contains(HEAD_MASON.toString())) {
                    HeadMason headMason = clientService.findHeadMasonById(potentialSiteDto.getHeadMason());
                    potentialSite.setHeadMason(headMason);
                } else {
                    potentialSite.setHeadMason(null);
                }
                if (potentialSiteDto.getPartnerType().contains(CONTRACTOR.toString())) {
                    Contractor contractor = clientService.findContractorById(potentialSiteDto.getContractor());
                    potentialSite.setContractor(contractor);
                } else {
                    potentialSite.setContractor(null);
                }
                if (potentialSiteDto.getPartnerType().contains(SITE_MANAGER.toString())) {
                    SiteManager siteManager = clientService.findSiteManagerById(potentialSiteDto.getSiteManager());
                    potentialSite.setSiteManager(siteManager);
                } else {
                    potentialSite.setSiteManager(null);
                }
            }

            if (potentialSiteDto.getEngineerRef() != null) {
                Engineer engineer = clientService.getEngineerById(potentialSiteDto.getEngineerRef());
                potentialSite.setEngineer(engineer);
            } else {
                potentialSite.setEngineer(null);
            }

        } catch (Exception e) {
            log.error("Potential site updating error :: {}", e.getMessage());
            throw new AesException("Potential site updating error: " + e.getMessage());
        }

    }

    @Override
    public List<PotentialSiteAllResponseDto> getAllApprovedPotentialSite() {

        List<PotentialSite> potentialSites = potentialSiteRepository.fetchAllPendingAndPotentialSites();

        List<PotentialSiteAllResponseDto> potentialSiteAllResponseDtos = new ArrayList<>();

        potentialSites.forEach(item -> {
            PotentialSiteAllResponseDto potentialSiteAllResponseDto = new PotentialSiteAllResponseDto();
            potentialSiteAllResponseDto.setId(item.getId());
            potentialSiteAllResponseDto.setSiteName(item.getPotentialSite());
            potentialSiteAllResponseDto.setHandedOverSiteId(item.getHandedOverSite() != null ? item.getHandedOverSite().getId() : null);
            potentialSiteAllResponseDtos.add(potentialSiteAllResponseDto);
        });

        return potentialSiteAllResponseDtos;
    }

    @Override
    public Page<SiteResponseType> getSites(Pageable pageable, String siteType, Optional<String> searchParamKey, Optional<String> searchParamValue) {
        Page<SiteResponseType> sites;
        String id = null;
        String potentialSite = null;
        String siteOwnerName = null;
        String projectContactNumber = null;
        String estVolIspat = null;
        String estVolCmt = null;
        String ihbName = null;

        Set<Long> bazaarIds = utils.resolveAccessibleBazaarIds(userService.getLoggedInUser());
        Long[] bazaarIdArray = (bazaarIds == null || bazaarIds.isEmpty())
                ? new Long[0]
                : bazaarIds.toArray(new Long[0]);
        boolean shouldBazaarFilterApply = bazaarIdArray.length > 0;


        if (searchParamKey.isPresent() && searchParamValue.isPresent()) {
            switch (searchParamKey.get()) {
                case "id":
                    id = searchParamValue.get();
                    break;
                case POTENTIAL_SITE:
                    potentialSite = searchParamValue.get();
                    break;
                case "siteOwnerName":
                    siteOwnerName = searchParamValue.get();
                    break;
                case PHONE:
                    projectContactNumber = searchParamValue.get();
                    break;
                case "estVolIspat":
                    estVolIspat = searchParamValue.get();
                    break;
                case "estVolCmt":
                    estVolCmt = searchParamValue.get();
                    break;
                case IHB_NAME:
                    ihbName = searchParamValue.get();
                    break;

                default:
                    break;
            }
        }

        if (siteType.equalsIgnoreCase("retained")) {
            sites = potentialSiteRepository.fetchRetainedSites(
                    pageable,
                    id,
                    potentialSite,
                    siteOwnerName,
                    projectContactNumber,
                    estVolIspat,
                    estVolCmt,
                    ihbName,
                    bazaarIdArray,
                    shouldBazaarFilterApply
            );
        } else if (siteType.equalsIgnoreCase("lost")) {
            sites = potentialSiteRepository.fetchLostSites(
                    pageable,
                    id,
                    potentialSite,
                    siteOwnerName,
                    projectContactNumber,
                    estVolIspat,
                    estVolCmt,
                    ihbName,
                    bazaarIdArray,
                    shouldBazaarFilterApply
            );
        } else if (siteType.equalsIgnoreCase("potential")) {
            sites = potentialSiteRepository.fetchPotentialSites(
                    pageable,
                    id,
                    potentialSite,
                    siteOwnerName,
                    projectContactNumber,
                    estVolIspat,
                    estVolCmt,
                    ihbName,
                    bazaarIdArray,
                    shouldBazaarFilterApply
            );
        } else throw new AesException("Invalid site type : " + siteType);
        return sites;
    }

    @Override
    public List<SiteForVisitProjection> getSiteForVisitProjectionList(String searchParamKey, String searchParamValue) {
        Long userId = userService.getLoggedInUserId();
        UserResponseDto userResponseDto = userService.getUserResponseDtoById(userId);
        String name = "";
        if (searchParamKey != null && !searchParamKey.isEmpty()
                && searchParamValue != null && !searchParamValue.isEmpty()
                && searchParamKey.equalsIgnoreCase("name")) {
            name = searchParamValue;
        }


        if (userResponseDto.getRoleName() == null) {
            throw new AesException("User's Role info not found");
        }

        if (userResponseDto.getRoleName().equalsIgnoreCase("SR")) {
            if (userResponseDto.getTerritories() == null) {
                throw new AesException("User's Territories info not found");
            }
            if (userResponseDto.getTerritories().isEmpty()) {
                throw new AesException("User's Territories info not found");
            }
            List<Long> territoryIds = userResponseDto.getTerritories()
                    .stream()
                    .map(TerritoryDto::getId)
                    .toList();
            return potentialSiteRepository.getSiteProjectionListForSrVisit(name, territoryIds);
        }
        if (userResponseDto.getRoleName().equalsIgnoreCase("BDO") ||
                userResponseDto.getRoleName().equalsIgnoreCase("CRO")) {
            if (userResponseDto.getBdTerritories() == null || userResponseDto.getBdTerritories().isEmpty()) {
                throw new AesException("Current User's BD territories info not found");
            }

            List<Long> bdTerritoryIds = userResponseDto.getBdTerritories()
                    .stream()
                    .map(TerritoryInfo::getId)
                    .toList();
            return potentialSiteRepository.getSiteForVisitProjectionList(name, bdTerritoryIds);
        }

        return Collections.emptyList();
    }

    @Override
    public List<SiteForVisitProjection> getSiteForVisitProjectionList2(String searchParamKey, String searchParamValue) {
        String name = "";
        if (searchParamKey != null && !searchParamKey.isEmpty()
                && searchParamValue != null && !searchParamValue.isEmpty()
                && searchParamKey.equalsIgnoreCase("name")) {
            name = searchParamValue;
        }

        User user = userService.getLoggedInUser();
        Set<Long> bazaars = utils.resolveAccessibleBazaarIds(user);
        if (bazaars == null || bazaars.isEmpty()) {
            throw new AesException("No accessible bazaars found for the logged-in user.");
        }
        Long[] bazaarIds = bazaars.toArray(new Long[0]);
        boolean shouldBazaarFilterApply = true;
        return potentialSiteRepository.getSiteForVisitProjectionList2(name, bazaarIds,shouldBazaarFilterApply);
    }


    public Page<ConvertedSiteResponseDto> getConvertedSiteList(String searchParamKey, String searchParamValue, Pageable pageable) {
        User user = userService.getLoggedInUser();
        if (user == null) {
            throw new AesException("User not found");
        }

        Set<Long> bazaars = utils.resolveAccessibleBazaarIds(user);
        if (bazaars == null || bazaars.isEmpty()) {
            throw new AesException("No accessible bazaars found for the logged-in user.");
        }
        Long[] bazaarIds = bazaars.toArray(new Long[0]);
        boolean shouldBazaarFilterApply = true;
        return potentialSiteRepository.getConvertedSitePaginatedList(searchParamKey, searchParamValue,CustomStatus.YES.name(), bazaarIds,shouldBazaarFilterApply, pageable);
    }

    public ConvertedSiteDto getConvertedSiteDetails(Long id) {
        PotentialSite potentialSite = potentialSiteRepository.findById(id).orElse(null);
        if (potentialSite == null) {
            throw new AesException("Potential Site not found");
        }

        if (potentialSite.getDeleteStatus().equals(CustomStatus.YES))
            throw new AesException("Potential Site is deleted");

        return potentialSiteRepository.findConvertedSiteDetails(id);
    }

    @Transactional
    @Override
    public List<PotentialSiteResponseDto> getSitesByBazaar(Long bazaarId) {
        Bazaar bazaar = bazaarRepository.findById(bazaarId).orElse(null);
        if (bazaar == null) {
            throw new AesException("Bazaar not found");
        }

        List<PotentialSite> potentialSites = potentialSiteRepository.findAllByBazaarIdAndHandedOverSiteIsNull(bazaarId);


        return potentialSites.stream().map(site -> {
            PotentialSiteResponseDto dto = new PotentialSiteResponseDto();
            dto.setId(site.getId())
                    .setCreatedAt(site.getCreatedAt())
                    .setCreatedBy(site.getCreatedBy())
                    .setUpdatedAt(site.getUpdatedAt())
                    .setUpdatedBy(site.getUpdatedBy())
                    .setSiteType(site.getSiteType())
                    .setPotentialSite(site.getPotentialSite())
                    .setSiteOwnerName(site.getSiteOwnerName())
                    .setProjectContactNumber(site.getProjectContactNumber())
                    .setAddress(site.getAddress())
                    .setEstVolIspat(site.getEstVolIspat())
                    .setEstVolCmt(site.getEstVolCmt())
                    .setStoriedBuilding(site.getStoriedBuilding())
                    .setStartStage(site.getStartStage())
                    .setEndStage(site.getEndStage())
                    .setEngineerType(site.getEngineerType())
                    .setRefEngineer(site.getRefEngineer())
                    .setNotes(site.getNotes())
                    .setIspatTerritoryName(site.getIspatTerritoryName())
                    .setIspatTerritoryTableId(site.getIspatTerritoryTableId())
                    .setVisitPhoto(site.getVisitPhoto())
                    .setStatus(site.getStatus())
                    .setPartnerType(site.getPartnerType())
                    .setSiteManager(site.getSiteManager() != null ? site.getSiteManager().getId() : null)
                    .setContractor(site.getContractor() != null ? site.getContractor().getId() : null)
                    .setHeadMason(site.getHeadMason() != null ? site.getHeadMason().getId() : null)
                    .setIhbName(site.getIhb() != null ? site.getIhb().getName() : null)
                    .setCompetitorName(site.getCompetitorName())
                    .setEngineerRef(site.getEngineer() != null ? site.getEngineer().getId() : null)
                    .setBazaarId(site.getBazaar() != null ? site.getBazaar().getId() : null)
                    .setBazaarName(site.getBazaar() != null ? site.getBazaar().getBazaarName() : null);
            return dto;
        }).toList();
    }

    private Brand getCompetitorOrThrow(Long brandId) {
        if (brandId == null) {
            return null;
        }
        return brandRepository.findById(brandId)
                .orElseThrow(() -> new AesException(BRAND_NOT_FOUND + brandId));
    }

}
